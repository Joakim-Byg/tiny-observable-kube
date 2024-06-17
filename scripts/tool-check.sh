#! /bin/bash

function missing_tools() {
  detected_missing_tools=()
  for tool in $*
  do
    if ! command -v "$tool" &> /dev/null
      then
        detected_missing_tools+=( "$tool" )
      fi
  done
  echo "${detected_missing_tools[@]}";
}


function check_tools() {
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  NC='\033[0m'

  detected_missing_tools=( $(missing_tools "curl" "git" "docker" "kind" "kubectl" "helm") )
  echo "missing tools: $detected_missing_tools"
  tools=("curl" "git" "docker")
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
  for missing in "${detected_missing_tools[@]}"
  do
    echo -e " ${RED}\U2298${NC} $missing: NOT present"
  done

  if [ 0 -lt ${#detected_missing_tools[@]} ]; then
    if [ $(uname -r | sed -n 's/.*\( *Microsoft *\).*/\1/ip') ];
    then
      ./wsl2/install-missing-tools.sh silent
      return 0
    else
      detected_missing_tools_str="${detected_missing_tools[*]}"
      echo "Please install [${detected_missing_tools_str// /", "}] before running this script again."
      return 1
    fi
  else
    return 0
  fi
  return 1
}