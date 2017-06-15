#!/bin/bash +x
# the purpose of this script is to update client binaries on an occasional basis
# child of ~/.workstation_setup

if /usr/bin/hash gem 2>/dev/null ; then
  # ~/.gemrc should prevent ri or rdoc files from being installed
  sudo /usr/local/bin/gem update --system --conservative --minimal-deps --no-verbose --force
  sudo /usr/local/bin/gem update --conservative --minimal-deps --no-verbose --force
  # to remove all ri and rdocs of installed gems:
  # sudo rm -vrf $(sudo gem env gemdir)/doc
fi
if [[ $(uname) == "Darwin" ]] ; then
  /usr/sbin/softwareupdate -ia
  /usr/local/bin/mas upgrade
  # /usr/local/bin/brew update
  /usr/local/bin/brew upgrade
  for cask1 in $(/usr/local/bin/brew cask outdated | awk '{print $1}') ; do
    # TODO: fix problems updating brew casks 1) reinstalling gcloud drops kubectl 2) reinstalling virtualbox as non-root
    if [[ ${cask1} =~ virtualbox ]] || \
      [[ ${cask1} =~ gcloud ]] ; then
      echo "Skipping reinstall of brew cask \"${cask1}\" as it has known issues"
      continue
    fi
    /usr/local/bin/brew cask reinstall ${cask1}
  done
  # /usr/local/bin/brew cask outdated | xargs /usr/local/bin/brew cask reinstall
elif [[ $(uname) == "Linux" ]] ; then
  # only proceed for Linux workstations
  if [[ $(runlevel | cut -d ' ' -f2) -le 3 ]] ; then
    echo "Quitting workstation setup on what appears to be a server"
    exit 0
  fi
  if [[ -f /etc/redhat-release ]] ; then
    sudo yum update -y
  elif [[ -f /etc/os-version ]] ; then
    sudo apt-get update && sudo apt-get upgrade -y
  fi
fi
if /usr/bin/hash npm 2>/dev/null ; then
  npm install npm -g
  npm update -g
fi
/usr/bin/hash /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/bin/gcloud 2>/dev/null && \
  /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/bin/gcloud components update
