#!/bin/bash +x
# the purpose of this script is to update client binaries on an occasional basis
# child of ~/.workstation_setup

if [[ $(uname) == "Darwin" ]] ; then
  echo -e "\nUpdating OSX system..."
  /usr/sbin/softwareupdate --install --all
  echo -e "\nUpdating OSX App Store apps..."
  /usr/local/bin/mas upgrade
  echo -e "\nUpdating brew..."
  /usr/local/bin/brew upgrade
  echo -e "\nUpdating brew casks..."
  for cask1 in $(/usr/local/bin/brew cask outdated | awk '{print $1}') ; do
    if [[ ${cask1} =~ virtualbox ]] ; then
      echo -e "\nSkipping reinstall of brew cask \"virtualbox\" (known issues with non-root installs at time of coding)."
      continue
    elif [[ ${cask1} =~ gcloud ]] ; then
      /usr/local/bin/brew cask reinstall ${cask1}
      echo -e "\nUpgrading gcloud cask requires reinstall of kubectl client..."
      sudo gcloud components install kubectl -q
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
  pip install --upgrade -r <( pip freeze )
  # for pkg in $(sudo -H pip list --outdated --format=columns | tail -n +3 | awk '{print $1}') ; do
  #   sudo -H pip install ${pkg} --upgrade
  # done
  # pip freeze -local | grep -v '^\-e' | cut -d= -f1 | xargs -n1 pip install -U
fi
if hash gcloud 2>/dev/null ; then
  echo -e "\nUpdating glcoud..."
  sudo gcloud components update --quiet
fi
# find and fix any ownership problems (~/.config/gcloud/logs/ appears to be a common offender)
sudo find ~ -user root -exec chown --changes corey.bar '{}' \;
