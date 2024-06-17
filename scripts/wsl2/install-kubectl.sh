#!/bin/bash

function install_kubectl(){
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  chmod +x ./kubectl
  sudo mv ./kubectl /usr/local/bin/kubectl

  read -p "Please enter your Windows username: " windowsUser

  mkdir -p ~/.kube
  ln -sf "/mnt/c/users/$windowsUser/.kube/config" ~/.kube/config
}
