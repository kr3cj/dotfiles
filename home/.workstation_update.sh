#!/usr/bin/env bash
set +x
LOG=/var/tmp/workstation_update_$(date +%Y-%m-%d-%H:%M:%S).log
(
# the purpose of this script is to update client binaries on an occasional basis
# child of ~/.workstation_setup

if [[ ${GHA_CI_RUN} != true ]]; then
  echo -e "Backup current macos configs..."
  defaults read > ~/.homesick/repos/dotfiles_private/home/.macos_current.json
  # [[ -l ~/.macos_current.json ]] ||   \
  #  ln -s ~/.homesick/repos/dotfiles_private/home/.macos_current.json ~/.macos_current.json
fi

# 3rd party package management
# if hash npm 2>/dev/null ; then
#   echo -e "Updating npm..."
#   npm install npm -g
#   npm update -g
# fi
# if hash gem 2>/dev/null && [[ ${GHA_CI_RUN} != true ]]; then
#   echo -e "\nUpdating gems..."
#   ~/.gemrc should prevent ri or rdoc files from being installed
#   sudo gem update --system --conservative --minimal-deps --no-verbose --force
#   sudo gem update --conservative --minimal-deps --no-verbose --force
#   to remove all ri and rdocs of installed gems:
#   sudo rm -vrf $(gem env gemdir)/doc
# fi
# if hash pip 2>/dev/null; then
#   echo -e "\nUpdating pip..."
#   python -m pip install --upgrade pip
#   pip install --upgrade setuptools
#   pip install --upgrade -r <( pip freeze )
#   # for pkg in $(sudo -H pip list --outdated --format=columns | tail -n +3 | awk '{print $1}') ; do
#   #   sudo -H pip install ${pkg} --upgrade
#   # done
#   # pip freeze -local | grep -v '^\-e' | cut -d= -f1 | xargs -n1 pip install -U
# fi
# if hash tmux 2>/dev/null ; then
#   echo -e "\nUpdating tmux plugins..."
#   ~/.tmux/plugins/tpm/bin/update_plugins all
# fi
# if hash gcloud 2>/dev/null && [[ ${GHA_CI_RUN} != true ]]; then
  # echo -e "\nUpdating glcoud..."
  # sudo gcloud components update --quiet
  # find and fix any ownership problems (~/.config/gcloud/logs/ appears to be a common offender)
  # sudo find -x ~/.config/ -user root -exec chown --changes ${LOGNAME} '{}' \;
# fi
# TODO: update chrome extensions (https://github.com/mdamien/chrome-extensions-archive/issues/8)

if [[ $(uname) == "Darwin" ]] ; then
  # must use old style path building since we're in bash
  BREWBIN_PATH="/usr/local/bin/brew"
  [[ "$(uname -m)" == "arm64" ]] && BREWBIN_PATH="/opt/homebrew/bin/brew"
  BASE_PATH="$(${BREWBIN_PATH} --prefix)"
  export PATH="${BASE_PATH}/bin:${BASE_PATH}/opt/asdf/libexec/bin/asdf:${LOG_NAME}/.asdf/shims:${PATH}"

  # echo -e "\nUpdating vscode extensions..."
  # for ext1 in $(code --list-extensions); do
  #   code --install-extension --force "${ext1}"
  # done
  # cd ~/build/all-repos
  echo -e "Updating stubborn config files to homesick repo"

  echo -e "\nUpdating brew packages..."
  # hack for weird virt-manager dependency (or just remove spice-gtk, virt-manager and virt-viewer)
  # brew uninstall --ignore-dependencies spice-protocol
  brew update
  brew upgrade # TODO: if asdf gets updated, must reshim plugins?
  brew upgrade --cask
  # dont rely on "brew upgrade --cask" to skip auto-updating casks. Loop over each instead
  # brew upgrade --cask
  for cask1 in $(brew outdated --cask --greedy | awk '{print $1}') ; do
    case ${cask1} in
      # alfred|android-file-transfer|balenaetcher|brave-browser|firefox|font-fira-code|font-fira-code-nerd-font|gimp|github|iterm2|keystore-explorer|microsoft-edge|spotify|visual-studio-code|warp|wireshark)
        # TODO: letting apps update themselves may mistakenly install them to /Applications intead of ~/Applications :(
        # docker|github|iterm2|slack|zoom
      android-file-transfer|brave-browser|github|microsoft-edge|spotify|visual-studio-code|wireshark)
        echo "Skipping cask \"${cask1}\" that should auto update itself" ;;
      *)
        echo "Upgrading cask \"${cask1}\"..."
        brew upgrade --cask ${cask1} ;;
    esac
  done

  # if [[ -e $(brew --prefix)/bin/apm ]] ; then
    # echo -e "\nUpdating atom editor plugins."
    # $(brew --prefix)/bin/apm upgrade --confirm false
  # fi

  echo -e "\nUpdating helm plugins."
  helm_binary="$($(brew --prefix asdf)/bin/asdf where helm)/bin/helm"
  for hplug in $(${helm_binary} plugin list | grep -v ^NAME | awk '{print $1}') ; do
    ${helm_binary} plugin update ${hplug}
  done
  echo -e "\nUpdating helm repos."
  for repo1 in $(${helm_binary} repo list | grep -v NAME | awk '{print $1}'); do
    ${helm_binary} repo update ${repo1}
  done

  echo -e "\nUpdating kubectl krew plugins."
  (
    # change to home dir to pick up .tool-versions for asdf
    cd ~
    # ~/.asdf/shims/kubectl krew system receipts-upgrade
    ~/.asdf/shims/kubectl krew upgrade
  )

  # echo -e "\nUpdating password manager." # done via cask
  # /usr/local/bin/op update

  echo -e "\nCleaning temporary files and securely delete trash."
  $(brew --prefix findutils)/libexec/gnubin/find ~/.Trash/ -type f -exec /bin/rm -vP '{}' \; || \
  echo "open System Preferences->Privacy & Security->Full Disk Access->Check iTerm.app"
  $(brew --prefix findutils)/libexec/gnubin/find ~/.Trash/ -type d -delete

  # brew cask cleanupb
  brew autoremove
  brew doctor
  brew cleanup -s
  # docker docker-machine docker-compose
  # for problematic_brews in kubernetes-helm ; do
    # brew link ${problematic_brews} --overwrite
  # done
  brew missing

  if hash asdf 2>/dev/null ; then
    echo -e "\nUpdating asdf plugins..."
    $(brew --prefix asdf)/bin/asdf plugin update --all
    # overwrite ${TOOL_FILE} with new releases

    echo -e "\nUpdating asdf tool versions..."
    # from https://gist.github.com/ig0rsky/fef7f785b940d13b52eb1b379bd7438d
    TOOL_FILE="${HOME}/.tool-versions"
    if [[ -f ${TOOL_FILE} ]]; then
      # backing up ${TOOL_FILE}
      cp -avL ${TOOL_FILE} ${TOOL_FILE}.$(date +%Y%m%d).backup

      # read each line of .tool-versions into array of tool+version
      [[ -f ${TOOL_FILE}.new ]] && :> ${TOOL_FILE}.new
      while read line1; do
        array=( ${line1} )
        tool1="${array[0]}"
        old_version1="${array[1]}" # ${old_version1%% *} to only grab first word
        new_version1=""

        # TODO: prevent "No compatible versions available" from becoming the new version
        case ${tool1} in
          \#)
            echo "Skipping commented line \"${line1}\""
            echo "${line1}" >> ${TOOL_FILE}.new ;;
          nodejs)
            echo "ATTENTION: nodejs install requires libtool PATH workaround github.com/nodejs/node/issues/2341:"
            echo "$ alias libtool=\"/usr/bin/libtool\""
            echo "$ asdf install nodejs $(asdf latest nodejs ${old_version1%\.*})"
            echo "$ unalias libtool" ;;
          python)
            echo "Skipping upgrade of locked asdf plugin \"${tool1}:${old_version1}\""
            echo "  (latest major/minor version for \"${tool1}\" is $($(brew --prefix asdf)/bin/asdf latest ${tool1}))"
            echo "${tool1} ${old_version1}" >> ${TOOL_FILE}.new ;;
          argocd|kubectl|viddy)
            # ASDF_HASHICORP_OVERWRITE_ARCH_TERRAFORM=x86_64 asdf install terraform 1.0.1
            echo "Getting latest patch version of asdf plugin \"${tool1}:${old_version1}\"..."
            echo "  (latest major/minor version for \"${tool1}\" is $($(brew --prefix asdf)/bin/asdf latest ${tool1}))"
            # use bash parameter expansion to extract the major and minor version from ${old_version1}
            new_version1="$($(brew --prefix asdf)/bin/asdf latest ${tool1} ${old_version1%\.*})"
            # if asdf dropped old_version, above will return emtpy string, so return old_version
            echo "${tool1} ${new_version1:=${old_version1}}" >> ${TOOL_FILE}.new ;;
          example2)
            echo "Getting latest minor version only of asdf plugin \"${tool}:${old_version1}\"..."
            echo "  (latest major/minor version for \"${tool1}\" is $($(brew --prefix asdf)/bin/asdf latest ${tool1}))"
            # use bash parameter expansion to extract the major version from ${old_version1}
            new_version1="$($(brew --prefix asdf)/bin/asdf latest ${tool1} ${old_version1%%\.*})"
            # if asdf dropped old_version, above will return emtpy string, so return old_version
            echo "${tool1} ${new_version1:=${old_version1}}" >> ${TOOL_FILE}.new ;;
          *)
            echo "Getting latest major version of asdf plugin \"${tool1}:${old_version1}\"..."
            new_version1="$($(brew --prefix asdf)/bin/asdf latest ${tool1})"
            # if above returns emtpy string (jq, terraform-docs) or "No compatible versions...", return old_version
            if [[ ${new_version1} == "" || ${new_version1} =~ "compatible" ]]; then
              echo "  WARNING!!! (latest major/minor version for \"${tool1}\" cannot be found!"
              echo "  Reverting to current version: ${old_version1}"
              new_version1=${old_version1}
            else
              new_version1="$($(brew --prefix asdf)/bin/asdf latest ${tool1} ${old_version1%%\.*})"
            fi
            # echo "${tool1} ${new_version1:=${old_version1}}" >> ${TOOL_FILE}.new ;;
            echo "${tool1} ${new_version1}" >> ${TOOL_FILE}.new ;;
        esac
      done < ${TOOL_FILE}

      echo -e "Now a diff of the version updates:...\n"
      diff ${TOOL_FILE}.$(/bin/date +%Y%m%d).backup ${TOOL_FILE}.new
      cat ${TOOL_FILE}.new > ${TOOL_FILE} && rm ${TOOL_FILE}.new
      (cd ${HOME} && $(brew --prefix asdf)/bin/asdf install)
      asdf reshim python krew
      echo "Finished updating asdf ${TOOL_FILE}"
      # TODO: Remove all unused versions automatically
      echo "Remove old asdf config files older than 30 days"
      $(brew --prefix findutils)/libexec/gnubin/find ${HOME}/ \
        -mindepth 1 \
        -maxdepth 1 \
        -type f \
        -name ".tool-versions\.*" \
        -mtime +30 \
        -print -delete
      ( cd ~; asdf install )
    fi
  fi

  if hash steampipe 2>/dev/null ; then
    echo -e "\nUpdating steampipe plugins..."
    steampipe plugin update --all
  fi

  /bin/rm -vr ~/.gradle/caches/* 2> /dev/null || echo
  /bin/rm -vr ~/.ivy2/{local,cache}/* 2> /dev/null || echo
  /bin/rm -vr ~/Library/Containers/com.apple.mail/Data/Library/Mail\ Downloads/* 2> /dev/null || echo
  if [[ ${GHA_CI_RUN} != true ]]; then
    # /usr/bin/sudo /bin/rm -vr /System/Library/Speech/Voices/* 2> /dev/null || echo
    # /usr/bin/sudo /bin/rm -vr /private/var/tmp/* 2> /dev/null || echo
    # /usr/bin/sudo /usr/sbin/purge
    # /usr/bin/sudo /usr/sbin/periodic daily weekly monthly
    # /usr/bin/sudo rm -vr ~/Library/Caches/*

    # ensure credential files for development are locked down
    for item1 in ~/.ivy2 ~/.docker ~/.ant ~/.m2 ~/.pgpass ~/.vnc/passwd ~/.jspm/config; do
      [[ -f ${item1} ]] && $(brew --prefix coreutils)/libexec/gnubin/chmod -c 600 ${item1}
      [[ -d ${item1} ]] && $(brew --prefix findutils)/libexec/gnubin/find ${item1} -type d -exec chmod -v 700 '{}' \;
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
    -name ".[^.]*" -not \( -name ".DS_Store" -or -name ".localized" \
    -or -name "*_history" -or -name "*hst" -or -name "*hist" \
    -or -name ".tool-versions.*" -or -name ".fzf.*" -or -name ".viminfo" \
    -or -name ".*_session_token" -or -name ".CFUserTextEncoding" \
    -or -name ".wget-hsts" -or -name ".zcompdump" \
    -or -name ".macos_*.json" -or -name .gitignore -or -name .yarnrc \) \
    -exec echo 'Unmanaged dotfile: {}; Track with \"homeshick track dotfiles <name>\"?' \;

  echo -e "\nPrint any repos with https auth..."
  for dir1 in ~/build/ ~/.homesick/repos/ ; do
    find ${dir1} -maxdepth 6 -path "*/.git/config" -exec grep -H https '{}' \;
  done

  echo -e "\nUpdating macos App Store apps..."
  # authenticate to apple account if necessary
  # if [[ ${GHA_CI_RUN} != true ]] && [[ ! $($(brew --prefix mas)/bin/mas account) ]]; then
  #   passman Apple && $(brew --prefix mas)/bin/mas signin appleid@${CUSTOM_HOME_DOMAIN}
  # fi
  # $(brew --prefix mas)/bin/mas/bin/mas upgrade
  # "$(brew --prefix mas)/bin/mas/bin/mas list" finds more with sudo prefix

  echo -e "\nUpdating macos system..."
  /usr/sbin/softwareupdate --install --all
  # /usr/sbin/softwareupdate --restart
  # sudo /usr/bin/xcode-select --switch /Library/Developer/CommandLineTools
  # sudo /usr/bin/xcodebuild -license accept 2> /dev/null
  if [[ ${GHA_CI_RUN} != true ]]; then
    # TODO: Must reboot immediately else the Finder can get disk sync issues and error -43?
    echo -e "\nChecking macos disk health."
    echo "Verifying disk health at $(/bin/date +%Y-%m-%d). \
    # This will freeze the system for a couple minutes." | /usr/bin/wall
    # for DEV in disk1 disk1s{1..4}; do
      # /usr/bin/sudo /usr/sbin/diskutil verifyVolume /dev/${DEV}
      # sudo diskutil repairVolume /dev/${DEV}
    # done
    /usr/bin/sudo /usr/sbin/diskutil verifyDisk /dev/disk0
    echo "Finished verifying disk health at $(/bin/date +%Y-%m-%d)." | /usr/bin/wall
    # sudo diskutil repairDisk /dev/disk0
  fi

elif [[ $(uname) == "Linux" ]] ; then
  # only proceed for Linux workstations, not servers
  if [[ ! -d /usr/share/xsessions ]] && [[ ${GHA_CI_RUN} != true ]]; then
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

if [[ ${GHA_CI_RUN} != true ]]; then
   echo -e "\nClear old log files."
  /usr/bin/find /var/tmp -type f -name "workstation_update_*.log" -user $(whoami) -mtime +90 -print -delete
fi
# close out logging
) 2>&1 | tee -a ${LOG}
