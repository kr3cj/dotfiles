#!/bin/bash +x
LOG=/var/tmp/workstation_update_$(date +%Y%m%d-%H%M).log
(
# the purpose of this script is to update client binaries on an occasional basis
# child of ~/.workstation_setup

# 3rd party package management
if hash npm 2>/dev/null ; then
  echo -e "Updating npm..."
  npm install npm -g
  npm update -g
fi
if hash gem 2>/dev/null && [[ ${TRAVIS_CI_RUN} != true ]]; then
  echo -e "\nUpdating gems..."
  # ~/.gemrc should prevent ri or rdoc files from being installed
  sudo gem update --system --conservative --minimal-deps --no-verbose --force
  sudo gem update --conservative --minimal-deps --no-verbose --force
  # to remove all ri and rdocs of installed gems:
  # sudo rm -vrf $(sudo gem env gemdir)/doc
fi
if hash pip 2>/dev/null; then
  echo -e "\nUpdating pip..."
  pip install --upgrade setuptools
  pip install --upgrade -r <( pip freeze )
  # for pkg in $(sudo -H pip list --outdated --format=columns | tail -n +3 | awk '{print $1}') ; do
  #   sudo -H pip install ${pkg} --upgrade
  # done
  # pip freeze -local | grep -v '^\-e' | cut -d= -f1 | xargs -n1 pip install -U
fi
if hash tmux 2>/dev/null ; then
  echo -e "\nUpdating tmux plugins..."
  ~/.tmux/plugins/tpm/bin/update_plugins all
fi
# if hash gcloud 2>/dev/null && [[ ${TRAVIS_CI_RUN} != true ]]; then
  # echo -e "\nUpdating glcoud..."
  # sudo gcloud components update --quiet
  # find and fix any ownership problems (~/.config/gcloud/logs/ appears to be a common offender)
  # sudo find -x ~/.config/ -user root -exec chown --changes ${LOGNAME} '{}' \;
# fi
# TODO: update chrome extensions (https://github.com/mdamien/chrome-extensions-archive/issues/8)

if [[ $(uname) == "Darwin" ]] ; then
  echo -e "\nUpdating code..."
  # cd ~/build/all-repos

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
  /usr/local/bin/apm upgrade --confirm false

  echo -e "\nCleaning temporary files."
  /usr/local/bin/brew cleanup -s
  /usr/local/bin/brew cask cleanup
  /usr/local/bin/brew doctor
  /usr/local/bin/brew missing
  /usr/local/bin/brew prune

  /bin/rm -vr ~/.gradle/caches/* 2> /dev/null || echo
  /bin/rm -vr ~/.ivy2/{local,cache}/* 2> /dev/null || echo
  /bin/rm -vr ~/Library/Containers/com.apple.mail/Data/Library/Mail\ Downloads/* 2> /dev/null || echo
  if [[ ${TRAVIS_CI_RUN} != true ]]; then
    /usr/bin/sudo /bin/rm -vr /System/Library/Speech/Voices/* || echo
    # /usr/bin/sudo /bin/rm -vr /private/var/tmp/* || echo
    /usr/bin/sudo /usr/sbin/purge
    /usr/bin/sudo /usr/sbin/periodic daily weekly monthly
    # /usr/bin/sudo rm -vr ~/Library/Caches/*
    # TODO: Must reboot immediately else the Finder disk sync issues and error -43?
    # echo -e "\nChecking macos disk health."
    # echo "Verifying disk health at $(date +%Y-%m-%d-%H%M). \
    # This will freeze the system for a couple minutes." | /usr/bin/wall
    # for DEV in disk1 disk1s{1..4}; do
      # /usr/bin/sudo /usr/sbin/diskutil verifyVolume /dev/${DEV}
      # sudo diskutil repairVolume /dev/${DEV}
    # done
    # /usr/bin/sudo /usr/sbin/diskutil verifyDisk /dev/disk0
    # echo "Finished verifying disk health at $(date +%Y-%m-%d-%H%M)." | /usr/bin/wall
    # sudo diskutil repairDisk /dev/disk0
  fi

  echo -e "\nUpdating OSX system..."
  /usr/sbin/softwareupdate --install --all

  echo -e "\nUpdating OSX App Store apps..."
  # authenticate to apple account if necessary
  if [[ ! $(/usr/local/bin/mas account) ]] && [[ ${TRAVIS_CI_RUN} != true ]]; then
    /usr/local/bin/lpass show --password --clip "Apple" && \
      /usr/local/bin/mas signin apple@${CUSTOM_HOME_DOMAIN}
    clear_clip
  fi
  /usr/local/bin/mas upgrade
elif [[ $(uname) == "Linux" ]] ; then
  # only proceed for Linux workstations, not servers
  if [[ ! -d /usr/share/xsessions ]] && [[ ${TRAVIS_CI_RUN} != true ]]; then
    echo "Quitting workstation setup on what appears to be a linux server"
    exit 0
  fi
  if [[ -f /etc/redhat-release ]] ; then
    sudo yum update -y
  elif [[ -f /etc/os-version ]] ; then
    sudo apt-get update && sudo apt-get upgrade -y
    # TODO: compare installed versions of devtools with latest available versions of devtools
  fi
fi

# close out logging
) 2>&1 | tee -a ${LOG}
