#! /bin/bash

function check_command_is_present() {
  if ! command -v $1 &> /dev/null
    then
        echo "$1: NOT found!"
        return 1
    fi
    echo " ✓ $1: $($1 $2 | head -n1)"
    return 0
}
function check_tools() {
  missingTools=()
  check_command_is_present curl --version
  if [ 0 -lt $? ]; then
    missingTools+=( "curl" )
  fi
  check_command_is_present git --version
  if [ 0 -lt $? ]; then
    missingTools+=( "git" )
  fi
  check_command_is_present docker --version
  if [ 0 -lt $? ]; then
    missingTools+=( "docker" )
  fi
  check_command_is_present kind version
  if [ 0 -lt $? ]; then
    missingTools+=( "kind" )
  fi
  check_command_is_present kubectl version
  if [ 0 -lt $? ]; then
    missingTools+=( "kubectl" )
  fi
  check_command_is_present helm version
  if [ 0 -lt $? ]; then
    missingTools+=( "helm" )
  fi
  if [ 0 -lt ${#missingTools[@]} ]; then
    echo "Following tools are missing [${missingTools[@]}], please install them before running this script again."
    return 1
  fi
  return 0
}

check_tools
if [ 0 -lt $? ]; then echo "Exit..."; exit 1; fi

#Create a KinD cluster
echo "Installing KinD with name: observability ..."
kind create cluster --name observability --config=kluster-config.yaml

# Add all repos at once
echo "Ensuring the helm repositories are available ..."
helm repo add vm https://victoriametrics.github.io/helm-charts/
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# install Victoria Metrics
echo "Installing VictoriaMetrics ..."
helm show values vm/victoria-metrics-single > resources/grafana/victoria-metrics/generated-values.yaml
helm install vmsingle vm/victoria-metrics-single -f resources/grafana/victoria-metrics/generated-values.yaml --namespace default

# Installing Tempo
echo "Installing Tempo ..."
helm upgrade --install tempo grafana/tempo --kube-context kind-observability

# Installing Grafana
echo "Installing Grafana ..."
helm upgrade -f resources/grafana/tempo/single-binary-grafana-values.yaml --install grafana grafana/grafana --kube-context kind-observability

# Installing OpenTelemetry parts
echo "Installing OpenTelemetry parts ..."
# Install just ServiceMonitor and PodMonitor
# NOTE: This GH issue put me on the right track: https://github.com/open-telemetry/opentelemetry-operator/issues/1811#issuecomment-1584128371
kubectl --context kind-observability apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.71.2/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml
kubectl --context kind-observability apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.71.2/example/prometheus-operator-crd/monitoring.coreos.com_podmonitors.yaml

# Install cert-manager, since it's a dependency of the OTel Operator
kubectl --context kind-observability apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.3/cert-manager.yaml

# Need to wait for cert-manager to finish before installing the operator
# Sometimes it takes a couple of minutes for cert-manager pods to come up
echo "Taking a 30 second nap while the cert-manager pods come up... "
sleep 5
echo "... if curious about who first made this easy; go to Adriana Villelas repository: https://github.com/avillela/otel-target-allocator-talk/tree/main"
sleep 25

# Install operator
kubectl --context kind-observability apply -f https://github.com/open-telemetry/opentelemetry-operator/releases/download/v0.94.0/opentelemetry-operator.yaml

# Configuring OpenTelemetry RBAC, TargetAllocator & Metric Collector
echo "Configuring OpenTelemetry RBAC, TargetAllocator & Metric Collector ..."

# Make a namespace for the OTel components
kubectl --context kind-observability apply -f resources/otel/01-otel-namespace.yaml

# Create the roles in the cluster, that OTel is dependant upon
kubectl --context kind-observability apply -f resources/otel/02-otel-rbac.yaml
sleep 10

# Setup the OTel-collector
kubectl --context kind-observability apply -f resources/otel/03-otel-collector.yaml

echo "All done!"
echo "Now all you need is your application and the instrumentation for your particular language stack (look to resources/otel/04-otel-instrumentation*)"
echo "Happy coding :-)"
echo ""
echo "To enable port-forwarding for e.g. Grafana, do:"
echo "export GRAFANA_POD_NAME=\$(kubectl get pods --namespace default -l \"app.kubernetes.io/name=grafana,app.kubernetes.io/instance=grafana\" -o jsonpath=\"{.items[0].metadata.name}\")"
echo "kubectl --namespace default port-forward \$GRAFANA_POD_NAME 3000"
echo "The Grafana Web-UI is now available at http://localhost:3000"
echo ""
