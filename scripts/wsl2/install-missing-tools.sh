#!/bin/bash

GREEN='\033[0;32m'
NC='\033[0m'

silent_detection=$1

source ../tool-check.sh&> /dev/null; source ./tool-check.sh &> /dev/null; source ./scripts/tool-check.sh &> /dev/null
detected_missing_tools=( $(missing_tools "curl" "git" "docker" "kind" "kubectl" "helm") )

tools=("curl" "git" "docker")
if [ -z "$silent_detection" ]; then
  for val in "${tools[@]}"
  do
    if [[ ! ${detected_missing_tools[@]} =~ $val ]]; then
      echo -e " ${GREEN}\U2713${NC} $val: $($val --version 2>&1 | head -n1)"
    fi
  done
  tools=("kind" "kubectl" "helm")
  for val in "${tools[@]}"
  do
    if [[ ! ${detected_missing_tools[@]} =~ $val ]]; then
      echo -e " ${GREEN}\U2713${NC} $val: $($val version 2>&1 | head -n1)"
    fi
  done
fi

if [ 0 -lt ${#detected_missing_tools[@]} ]; then

  detected_missing_tools_str="${detected_missing_tools[*]}"
  read -p "Press enter to install [${detected_missing_tools_str// /", "}] (Ctrl+c to escape)";

  echo "Installing tools may require you to enter your Windows username and/or root-password ..."
  sudo apt-get update

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
