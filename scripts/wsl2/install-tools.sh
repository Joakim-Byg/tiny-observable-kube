#!/bin/bash

source ../tool-check.sh
detected_missing_tools=( $(missing_tools "curl" "git" "docker" "kind" "kubectl" "helm") )

tools=("curl" "git" "docker")
for val in "${tools[@]}"
do
  if [[ ! ${detected_missing_tools[@]} =~ $val ]]; then
    echo " ✓ $val: $($val --version 2>&1 | head -n1)"
  fi
done
tools=("kind" "kubectl" "helm")
for val in "${tools[@]}"
do
  if [[ ! ${detected_missing_tools[@]} =~ $val ]]; then
    echo " ✓ $val: $($val version 2>&1 | head -n1)"
  fi
done

if [ 0 -lt ${#detected_missing_tools[@]} ]; then
  echo "The following tools are missing:"
  for missing in "${detected_missing_tools[@]}"
  do
    echo "$missing"
  done
  read -p "Press enter to install (Ctrl+c to escape)";

  if [[ ${detected_missing_tools[@]} =~ "curl" ]]; then
    echo "Installing curl"
    ./install-curl.sh
  fi
  if [[ ${detected_missing_tools[@]} =~ "git" ]]; then
    echo "Installing git"
    ./install-git.sh
  fi
  if [[ ${detected_missing_tools[@]} =~ "docker" ]]; then
    echo "Installing docker"
    ./install-docker-ce.sh
  fi
  if [[ ${detected_missing_tools[@]} =~ "kind" ]]; then
    echo "Installing kind"
    ./install-kind.sh
  fi
  if [[ ${detected_missing_tools[@]} =~ "kubectl" ]]; then
    echo "Installing kubectl"
    ./install-kubectl.sh
  fi
  if [[ ${detected_missing_tools[@]} =~ "helm" ]]; then
    echo "Installing helm"
    ./install-helm.sh
  fi
else
  echo "You are all set, nothing further to install."
fi
