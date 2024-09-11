#! /bin/bash
base_dir=$(basename "`pwd`")
folder_prefix="./"
if [[ "$base_dir" == "wsl2" ]]; then folder_prefix="../../"; elif [[ "$base_dir" == "scripts" ]]; then folder_prefix="../"; fi

source ${folder_prefix}/scripts/tool-check.sh

check_tools
if [ 0 -lt $? ]; then echo "Exit..."; exit 1; fi

#Create a KinD cluster
echo "Installing KinD with name: observability from config: ${folder_prefix}kluster-config.yaml ..."
kind create cluster --name observability --config=${folder_prefix}kluster-config.yaml

# Add all repos at once
echo "Ensuring the helm repositories are available ..."
helm repo add vm https://victoriametrics.github.io/helm-charts/
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# install Victoria Metrics
echo "Installing VictoriaMetrics ..."
helm show values vm/victoria-metrics-single > ${folder_prefix}resources/grafana/victoria-metrics/generated-values.yaml
helm upgrade --install vmsingle vm/victoria-metrics-single -f ${folder_prefix}resources/grafana/victoria-metrics/generated-values.yaml --kube-context kind-observability

# Installing Tempo
echo "Installing Tempo ..."
helm upgrade --install tempo grafana/tempo --kube-context kind-observability

# Installing Grafana
echo "Installing Grafana ..."
helm upgrade --install -f ${folder_prefix}resources/grafana/tempo/single-binary-grafana-values.yaml grafana grafana/grafana --kube-context kind-observability

# Installing OpenTelemetry parts
echo "Installing OpenTelemetry parts ..."
# Install just ServiceMonitor and PodMonitor
# NOTE: This GH issue put me on the right track: https://github.com/open-telemetry/opentelemetry-operator/issues/1811#issuecomment-1584128371
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.71.2/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml --context kind-observability
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.71.2/example/prometheus-operator-crd/monitoring.coreos.com_podmonitors.yaml --context kind-observability

# Install cert-manager, since it's a dependency of the OTel Operator
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.3/cert-manager.yaml --context kind-observability

# Need to wait for cert-manager to finish before installing the operator
# Sometimes it takes a couple of minutes for cert-manager pods to come up
echo "Taking a 30 second nap while the cert-manager pods come up... "
sleep 5
echo "... if curious about who first made this easy; go to Adriana Villelas repository: https://github.com/avillela/otel-target-allocator-talk/tree/main"
sleep 25

# Install operator
kubectl apply -f https://github.com/open-telemetry/opentelemetry-operator/releases/download/v0.94.0/opentelemetry-operator.yaml --context kind-observability

# Configuring OpenTelemetry RBAC, TargetAllocator & Metric Collector
echo "Configuring OpenTelemetry RBAC, TargetAllocator & Metric Collector ..."

# Make a namespace for the OTel components
kubectl apply -f ${folder_prefix}resources/otel/01-otel-namespace.yaml --context kind-observability

# Create the roles in the cluster, that OTel is dependant upon
kubectl apply -f ${folder_prefix}resources/otel/02-otel-rbac.yaml --context kind-observability
sleep 10

# Setup the OTel-collector
kubectl apply -f ${folder_prefix}resources/otel/03-otel-collector.yaml --context kind-observability

# Installing promtail log-forwarding and loki for log-collecting
echo "Installing loki in single instance mode"
helm upgrade --install --values ${folder_prefix}resources/grafana/loki/loki-single-bin-helm-values.yaml loki grafana/loki --kube-context kind-observability
echo "Installing promtail as a daemon set, with the configs to loki"
helm upgrade --install --values ${folder_prefix}resources/grafana/loki/promtail-overrides.yaml promtail grafana/promtail --kube-context kind-observability

echo "All done!"
echo "Now all you need is your application and the instrumentation for your particular language stack (look to resources/otel/04-otel-instrumentation*)"
echo "Happy coding :-)"
echo ""
echo "To enable port-forwarding for e.g. Grafana, do:"
echo "export GRAFANA_POD_NAME=\$(kubectl get pods --namespace default -l \"app.kubernetes.io/name=grafana,app.kubernetes.io/instance=grafana\" -o jsonpath=\"{.items[0].metadata.name}\")"
echo "kubectl --namespace default port-forward \$GRAFANA_POD_NAME 3000"
echo "The Grafana Web-UI is now available at http://localhost:3000"
echo ""
