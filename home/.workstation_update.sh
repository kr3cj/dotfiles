#!/usr/bin/env bash +x
LOG=/var/tmp/workstation_update_$(date +%Y-%m-%d).log
(
# the purpose of this script is to update client binaries on an occasional basis
# child of ~/.workstation_setup

if [[ ${TRAVIS_CI_RUN} != true ]]; then
  echo -e "Backup current osx configs..."
  defaults read > ~/.homesick/repos/dotfiles_private/.osx_current.json
  # [[ -l ~/.osx_current.json ]] ||   \
  #  ln -s ~/.homesick/repos/dotfiles_private/.osx_current.json ~/.osx_current.json
fi

# 3rd party package management
if hash npm 2>/dev/null ; then
  echo -e "Updating npm..."
  npm install npm -g
  npm update -g
fi
if hash gem 2>/dev/null && [[ ${TRAVIS_CI_RUN} != true ]]; then
  echo -e "\nUpdating gems..."
  # ~/.gemrc should prevent ri or rdoc files from being installed
  # sudo gem update --system --conservative --minimal-deps --no-verbose --force
  # sudo gem update --conservative --minimal-deps --no-verbose --force
  # to remove all ri and rdocs of installed gems:
  sudo rm -vrf $(sudo gem env gemdir)/doc
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
  # echo -e "\nUpdating code..."
  # cd ~/build/all-repos
  echo -e "Updating stubborn config files to homesick repo"
  cp -av ~/.kube/config ~/.homesick/repos/dotfiles_private/home/.kube/
  cp -av ~/.docker/*.json ~/.homesick/repos/dotfiles_private/home/.docker/
  [[ -d ~/.homesick/repos/dotfiles/home/.code ]] || mkdir ~/.homesick/repos/dotfiles/home/.code
  cp -av ~/Library/Application\ Support/Code/User/settings.json \
    ~/.homesick/repos/dotfiles/home/.code/settings.json

  # echo -e "\nUpdating work specific yeoman tools..."
  # for generator1 in $(yo --generators | grep /); do
  #   npm install --global ${generator/\//\/generator-}
  # done

  echo -e "\nUpdating brew..."
  # hack for weird virt-manager dependency (or just remove spice-gtk, virt-manager and virt-viewer)
  /usr/local/bin/brew uninstall --ignore-dependencies spice-protocol
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

  # echo -e "\nUpdating helm plugins."
  # for hplug in $(helm plugin list | grep -v ^NAME | awk '{print $1}') ; do
  #   # how to qualify path to asdf helm...
  #   su - coreybar -c "${helm plugin update ${hplug}"
  # done

  echo -e "\nCleaning temporary files and securely delete trash."
  PATH="/usr/local/bin:${PATH}"
  /usr/local/bin/brew cleanup -s
  /bin/rm -vP ~/.Trash/*

  # /usr/local/bin/brew cask cleanup
  /usr/local/bin/brew doctor
  # docker docker-machine docker-compose
  # for problematic_brews in kubernetes-helm ; do
    # /usr/local/bin/brew link ${problematic_brews} --overwrite
  # done
  /usr/local/bin/brew missing

  if hash asdf 2>/dev/null ; then
    echo -e "\nUpdating asdf plugins..."
    $(brew --prefix asdf)/bin/asdf plugin-update --all
  fi

  /bin/rm -vr ~/.gradle/caches/* 2> /dev/null || echo
  /bin/rm -vr ~/.ivy2/{local,cache}/* 2> /dev/null || echo
  /bin/rm -vr ~/Library/Containers/com.apple.mail/Data/Library/Mail\ Downloads/* 2> /dev/null || echo
  if [[ ${TRAVIS_CI_RUN} != true ]]; then
    /usr/bin/sudo /bin/rm -vr /System/Library/Speech/Voices/* 2> /dev/null || echo
    # /usr/bin/sudo /bin/rm -vr /private/var/tmp/* 2> /dev/null || echo
    /usr/bin/sudo /usr/sbin/purge
    /usr/bin/sudo /usr/sbin/periodic daily weekly monthly
    # /usr/bin/sudo rm -vr ~/Library/Caches/*

    # ensure credential files for development are locked down
    for item1 in ~/.ivy2 ~/.docker ~/.ant ~/.m2 ~/.pgpass ~/.vnc/passwd ~/.jspm/config ~/.code/settings.json; do
      [[ -f ${item1} ]] && chmod -v 600 ${item1}
      [[ -d ${item1} ]] && chmod -vR 700 ${item1}
    done
  fi

  echo -e "\nPrint any dead links in home directory..."
  $(brew --prefix findutils)/libexec/gnubin/find ${HOME} \
    -xtype l \
    ! -path "*/Library/*" \
    ! -path "*/.virtualenvs/*" \
    ! -path "*/build/*" \
    -exec echo 'Broken symlink: {}' \; 2> /dev/null
    # -exec rm -v '{}' \;

  echo -e "\nPrint any unmanaged dotfiles..."
  $(brew --prefix findutils)/libexec/gnubin/find ${HOME} -mindepth 1 -maxdepth 2 -type f \
    -exec echo 'Unmanaged dotfile: {}; Track with \"homeshick track dotfiles <name>\"?' \;


  echo -e "\nPrint any repos with https auth..."
  for dir1 in ~/build/ ~/.homesick/repos/ ; do
    find ${dir1} -maxdepth 6 -path "*/.git/config" -exec grep https '{}' \;
  done

  echo -e "\nUpdating OSX App Store apps..."
  # authenticate to apple account if necessary
  if [[ ${TRAVIS_CI_RUN} != true ]] && [[ ! $(/usr/local/bin/mas account) ]]; then
    /usr/local/bin/lpass show --password --clip "Apple" && \
      /usr/local/bin/mas signin apple@${CUSTOM_HOME_DOMAIN}
  fi
  /usr/local/bin/mas upgrade

  echo -e "\nUpdating OSX system..."
  /usr/sbin/softwareupdate --install --all
  # /usr/sbin/softwareupdate --restart
  if [[ ${TRAVIS_CI_RUN} != true ]]; then
    # TODO: Must reboot immediately else the Finder can get disk sync issues and error -43?
    echo -e "\nChecking macos disk health."
    echo "Verifying disk health at $($(brew --prefix coreutils)/libexec/gnubin/date --rfc-3339=seconds). \
    # This will freeze the system for a couple minutes." | /usr/bin/wall
    # for DEV in disk1 disk1s{1..4}; do
      # /usr/bin/sudo /usr/sbin/diskutil verifyVolume /dev/${DEV}
      # sudo diskutil repairVolume /dev/${DEV}
    # done
    /usr/bin/sudo /usr/sbin/diskutil verifyDisk /dev/disk0
    echo "Finished verifying disk health at $($(brew --prefix coreutils)/libexec/gnubin/date --rfc-3339=seconds)." | /usr/bin/wall
    # sudo diskutil repairDisk /dev/disk0
  fi

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

if [[ ${TRAVIS_CI_RUN} != true ]]; then
   echo -e "\nClear old log files."
  /usr/bin/find /var/tmp -type f -name "workstation_update_*.log" -user $(whoami) -mtime +60 -print -delete
fi
# close out logging
) 2>&1 | tee -a ${LOG}
