# Creating an observable kind-cluster for local Cloud Native experimenting
The purpose of this tiny local kubernetes setup is to provide a simplest and best in breed tool stack to accommodate
the concept of "environment parity" all the way down to your local machine. The benefits should be, that by having the 
observability and troubleshooting tools available during development on our local setup, we get practice and experience 
with these, which may foster us being better at making the correct tracing hooks and metric counters and guages, to 
eventually assist a better troubleshooting situations in a future production context.

This minimal project makes a Grafana explorer available to us. Within grafana we want to monitor our system metrics and 
system traces; especially we want to, through tinkering get good at creating really informative traces for our 
microservice and polyglot systems.
For this we install single-instances of the products tempo and VictoriaMetrics.
- VictoriaMetrics is easy to work with and acts as a fully compatible prometheus backend within Grafana.
- Tempo is the storage componentes needed for our traces.

Eventually we will bind it together with OpenTelemetry, which today is quite able to instrument and receive traces and 
scrape metrics in a comparable matter to that of other metric scrapers in the CNCF landscape.

The image below illustrates the relationship between the various components - and why we need each of them.


## Getting started

begin by installing tools:
* curl
* git
* Docker
* KinD aka Kubernetes in Docker
* kubectl aka. kubernetes-cli
* helm
* (k9s not needed but nice for quality of life reasons)

TL;DR; execute:
```shell
./justgivetittome.sh
```
If something fails, the rest of the README provides knowledge into each step; and at least you should read step 3 in the
last section about applications.

Otherwise, follow the below steps 🙂

Create a KinD cluster with two workers and a control node as specified by `./kluster-config.yaml`
```shell
kind create cluster --name observability --config=kluster-config.yaml
```
To delete the cluster again call
```shell
kind delete cluster --name observability
```

Now lets look into installing the various components

## Installing Victoria Metrics
This section is based on https://github.com/VictoriaMetrics/helm-charts/tree/master/charts/victoria-metrics-single

__**Notice**__, this is the _single version_ and should not be used for non-local kubernetes instances.
1. Begin by adding victoria metrics to the local helm repo:
   ```shell
   # Add Victoria metrics’ chart repository to Helm:
   helm repo add vm https://victoriametrics.github.io/helm-charts/
   # Update the chart repository:
   helm repo update
   # Check the single-instance is available
   helm search repo vm/victoria-metrics-single -l
   ```
2. Create the configuration file `values.yaml` (the single version):
   ```yaml
   helm show values vm/victoria-metrics-single > resources/grafana/victoria-metrics/generated-values.yaml
   ```
3. Deploy the Loki cluster using (we have placed our values in `resources/grafana/loki/loki-values.yaml`:
   ```shell
   # Test/dry-run if need be.
   helm install vmsingle vm/victoria-metrics-single -f resources/grafana/victoria-metrics/generated-values.yaml --namespace default --debug --dry-run
   # Install with
   helm install vmsingle vm/victoria-metrics-single -f resources/grafana/victoria-metrics/generated-values.yaml --namespace default
   ```

## Installing Tempo

This section is based on https://github.com/grafana/tempo/tree/main/example/helm #Single Binary

Since we are building for KinD and a local setup, we cannot rely on S3 and API based storage technologies. Instead, we
utilise the local storage at KinD worker nodes, which in turn means we have to have Tempo run in
"Single Binary"/"monolithic mode" instead of fully distributed, which is not desirable for production graded setups,
but we accept for this local setup.

```shell
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm upgrade --install tempo grafana/tempo --kube-context kind-observability
```
## Installing Grafana

Since we have already added Grafana to our helm repositories, we can install Grafana, quit simply with a single command:
```shell
helm upgrade -f grafana/tempo/single-binary-grafana-values.yaml --install grafana grafana/grafana --kube-context kind-observability
# Extras
#kubectl create -f grafana/tempo/single-binary-extras.yaml --context kind-observability
```
To get the admin password for the grafana installation, execute the following:
```shell
kubectl get secret --namespace default grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```
To access the grafana web-ui, do:

```shell
export GRAFANA_POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=grafana" -o jsonpath="{.items[0].metadata.name}")
kubectl --namespace default port-forward $GRAFANA_POD_NAME 3000
```

## Open telemetry and your application (OTel & App)

Next steps are inspired by https://github.com/avillela/otel-target-allocator-talk

1. Install the OpenTelemetry operator and its dependencies: 
   ```shell
   # Install just ServiceMonitor and PodMonitor
   # NOTE: This GH issue put me on the right track: https://github.com/open-telemetry/opentelemetry-operator/issues/1811#issuecomment-1584128371
   kubectl --context kind-observability apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.71.2/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml
   kubectl --context kind-observability apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.71.2/example/prometheus-operator-crd/monitoring.coreos.com_podmonitors.yaml
   
   # Install cert-manager, since it's a dependency of the OTel Operator
   kubectl --context kind-observability apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.3/cert-manager.yaml
   
   # Need to wait for cert-manager to finish before installing the operator
   # Sometimes it takes a couple of minutes for cert-manager pods to come up
   
   # Install operator
   kubectl --context kind-observability apply -f https://github.com/open-telemetry/opentelemetry-operator/releases/download/v0.94.0/opentelemetry-operator.yaml
   ```
   
2. This next section is near identical to that of step
   [3a](https://github.com/avillela/otel-target-allocator-talk/blob/main/README.md#3a---kubernetes-deployment-collector-stdout-only) 
   in https://github.com/avillela/otel-target-allocator-talk, except I have seperated the OTel section and the 
   application section. Also, in the below example i have chosen instrumentation for GoLang - go pick your favorite 
   dialects in the resources `./resources/otel` prepended with  `04-otel-instrumentation`:
   ```shell
   # Make a namespace for the OTel components
   kubectl --context kind-observability apply -f resources/otel/01-otel-namespace.yaml
   
   # Create the roles in the cluster, that OTel is dependant upon
   kubectl --context kind-observability apply -f resources/otel/02-otel-rbac.yaml
   
   # Setup the OTel-collector
   kubectl --context kind-observability apply -f resources/otel/03-otel-collector.yaml
   
   # Declare the OTel-instrumentation of the applications we want to trace
   kubectl --context kind-observability apply -f resources/otel/04-otel-instrumentation-golang.yaml
   ```
   These steps are collected in the `apply-otel-resources.sh`
3. Either you have a container ready for this project, otherwise look to the readme placed in 
   https://github.com/Joakim-Byg/tiny-blog.

   To make a container image available without an actual container registry (very reminiscent of some development 
   scenarios), call:
   ```shell
   kind --name observability load docker-image my.favorite.container:1.0.0
   ```
   This loads the container image into kind, for making eventual deployments references available without an actual
   container registry.
4. Adjust the application yaml files in `./resources/app` accordingly to your container and what service name and config
   you need (somebody should look into kube-app-deployment-boilerplate 🤔):
   ```shell
   # Declare the service monitoring of the eventual k8s-services for the applications
   kubectl apply -f resources/app/service-monitoring.yaml

   # And finally, declare the deployment and service manifests of the applications
   kubectl apply -f resources/app/application-deployments.yaml
   ```

Et Voila! You now have your very own application running in a local kubernetes cluster with metrics and trace tools 
readily available.

Happy coding!
