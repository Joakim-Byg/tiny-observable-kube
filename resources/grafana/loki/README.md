# Get Logging with Promtail, Loki and Grafana
Before anything make sure grafana is added to helm:
```shell
helm  
```
## Install Loki
Install with helm with the default values inspired by: https://github.com/grafana/loki/blob/main/production/helm/loki/single-binary-values.yaml
with the modification that `loki.auth_enabled: false`.
```shell
helm install --values resources/grafana/loki/loki-single-bin-helm-values.yaml loki grafana/loki --kube-context kind-observability
```
## Install promtail
Promtail installation was found at: https://akyriako.medium.com/kubernetes-logging-with-grafana-loki-promtail-in-under-10-minutes-d2847d526f9e

First we get the default values:
```shell
helm show values grafana/promtail > resources/grafana/loki/promtail-overrides.yaml
```
Inside `resources/grafana/loki/promtail-overrides.yaml` at the line with nested key `config.clients.url[]` has
`http://loki-gateway.default.svc.cluster.local/loki/api/v1/push`
```yaml
# ...
config:
  # ...
  clients:
    - url: http://loki-gateway.default.svc.cluster.local/loki/api/v1/push
# ...
```
Now run:
```shell
helm install --values resources/grafana/loki/promtail-overrides.yaml promtail grafana/promtail --kube-context kind-observability
```
