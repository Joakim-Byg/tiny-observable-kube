## Helm

Congratulations! You have successfully found the Helm examples. These examples are meant for
advanced users looking to deploy Tempo in a microservices pattern. If you are just getting started
might I recommend the [docker-compose examples](../docker-compose). The docker-compose examples also are much
better at demonstrating trace discovery flows using Loki and other tools.

If you're convinced this is the place for you then keep reading!

### Initial Steps

To test the Helm example locally requires:

- helm > v3.0.0

Ensure you have a k8s-like cluster locally provisioned

Next deploy the single binary.

### Single Binary

**Note: This method of deploying Tempo is referred to by documentation as "monolithic mode"**

The Tempo single binary configuration is currently setup to store traces locally on disk, but can easily be configured to
store them in an S3 or GCS bucket. See configuration docs or some of the other examples for help.

> Note: double check you're applying to your local k3d before running this!

```console
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

Install Tempo, Grafana and synthetic-load-generator

```console
helm upgrade --install tempo grafana/tempo
helm upgrade -f single-binary-grafana-values.yaml --install grafana grafana/grafana
kubectl create -f single-binary-extras.yaml
```

### Find Traces

Navigate to http://localhost:3000/explore and try a simple TraceQL query like `{}`

### Clean up

```console

```