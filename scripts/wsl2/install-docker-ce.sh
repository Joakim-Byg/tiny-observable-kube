#!/bin/bash


function install_docker(){
  # 1) Add Docker's apt repository
  # 1.1) Add Docker's official GPG key:

  sudo apt-get install ca-certificates curl
  sudo install -m 0755 -d /etc/apt/keyrings
  os_string=$(cat /etc/issue | head -1 | awk '{print tolower($0)}')
  os=""
  if [[ $os_string =~ "debian" ]]; then os="debian"; elif [[ $os_string =~ "ubuntu" ]]; then os="ubuntu"; fi
  sudo curl -fsSL https://download.docker.com/linux/${os}/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  # 1.2) Add the repository to Apt sources:
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${os} \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update

  # 2) install docker-ce
  if [[ "$os" == "debian" ]]; then
    echo "Cleanup before install"
    sudo apt-get remove docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo apt-get autoremove
    sudo apt-get autoclean
    # from https://github.com/Microsoft/WSL/issues/2288
    if ([ -x "/etc/init.d/docker" ] || [ -e "/etc/init/docker.conf" ]) && [ "$1" = remove ]; then
      invoke-rc.d docker stop || exit $?
    fi
  fi

  echo "Installing ..."
  sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  # 3) linux post-installs
  echo "post-install processes ..."
  if ! grep "^docker:" /etc/group &> /dev/null
  then
    sudo groupadd docker &> /dev/null
  fi
  sudo usermod -aG docker $USER
  newgrp docker
  if [[ "$os" == "debian" ]]; then
#    dpkg-reconfigure docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    echo "Starting docker service ..."
    sleep 2
    sudo service docker start
  fi
}