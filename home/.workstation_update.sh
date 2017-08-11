#!/bin/bash +x
# the purpose of this script is to update client binaries on an occasional basis
# child of ~/.workstation_setup

if [[ $(uname) == "Darwin" ]] ; then
  echo -e "\nUpdating OSX system..."
  /usr/sbin/softwareupdate -ia
  echo -e "\nUpdating OSX App Store apps..."
  /usr/local/bin/mas upgrade
  echo -e "\nUpdating brew..."
  /usr/local/bin/brew upgrade
  echo -e "\nUPdating brew casks..."
  for cask1 in $(/usr/local/bin/brew cask outdated | awk '{print $1}') ; do
    if [[ ${cask1} =~ virtualbox ]] ; then
      echo -e "\nSkipping reinstall of brew cask \"virtualbox\" (known issues with non-root installs at time of coding)."
      continue
    elif [[ ${cask1} =~ gcloud ]] ; then
      /usr/local/bin/brew cask reinstall ${cask1}
      echo -e "\nUpgrading gcloud cask requires reinstall of kubectl client..."
      gcloud components install kubectl -q
      continue
    fi
    /usr/local/bin/brew cask reinstall ${cask1}
  done
  echo -e "\nUpdating atom editor plugins."
  echo yes | /usr/local/bin/apm upgrade
elif [[ $(uname) == "Linux" ]] ; then
  # only proceed for Linux workstations
  if [[ $(runlevel | cut -d ' ' -f2) -le 3 ]] ; then
    echo -e "\nQuitting workstation update on what appears to be a server"
    exit 0
  fi
  if [[ -f /etc/redhat-release ]] ; then
    sudo yum update -y
  elif [[ -f /etc/os-version ]] ; then
    sudo apt-get update && sudo apt-get upgrade -y
  fi
fi

# 3rd party package management
if hash npm 2>/dev/null ; then
  "Updating npm..."
  npm install npm -g
  npm update -g
fi
if hash gem 2>/dev/null ; then
  echo -e "\nUpdating gems..."
  # ~/.gemrc should prevent ri or rdoc files from being installed
  sudo gem update --system --conservative --minimal-deps --no-verbose --force
  sudo gem update --conservative --minimal-deps --no-verbose --force
  # to remove all ri and rdocs of installed gems:
  # sudo rm -vrf $(sudo gem env gemdir)/doc
fi
if hash pip 2>/dev/null ; then
  echo -e "\nUpdating pip..."
  for pkg in $(pip list --outdated | awk '{print $1}') ; do
    sudo pip install ${pkg} --upgrade
  done
fi
if hash gcloud 2>/dev/null ; then
  echo -e "\nUpdating glcoud..."
  gcloud components update --quiet
fi
