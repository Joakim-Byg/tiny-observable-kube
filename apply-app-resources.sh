#! /bin/bash

# Declare the service monitoring of the eventual k8s-services for the applications
kubectl apply -f resources/service-monitoring.yaml

# And finally, declare the deployment and service manifests of the applications
kubectl apply -f resources/application-deployments.yaml
