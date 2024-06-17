#!/bin/bash

function install_git(){
  sudo apt-get install git

  read -p "Please enter name stamped onto git-commits (e.g. John Doe):" name
  read -p "Please enter email stamped onto git-commits (e.g. john@doe.com): " email

  git config --global user.name $name
  git config --global user.email $email
}
