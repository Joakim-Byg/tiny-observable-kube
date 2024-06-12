#!/bin/bash

# Receives your Windows username as only parameter.

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl

windowsUser=$1

mkdir -p ~/.kube
ln -sf "/mnt/c/users/$windowsUser/.kube/config" ~/.kube/config