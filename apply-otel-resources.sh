#! /bin/bash

# Make a namespace for the OTel components
kubectl apply -f resources/otel/01-otel-namespace.yaml

# Create the roles in the cluster, that OTel is dependant upon
kubectl apply -f resources/otel/02-otel-rbac.yaml

# Setup the OTel-collector
kubectl apply -f resources/otel/03-otel-collector.yaml

# Declare the OTel-instrumentation of the applications we want to trace
kubectl apply -f resources/otel/04-otel-instrumentation-golang.yaml
