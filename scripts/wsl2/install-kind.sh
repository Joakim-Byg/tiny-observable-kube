#!/bin/bash

echo "Installing KinD (This mey require you to enter root-password):"
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind