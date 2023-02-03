#!/bin/zsh
LOG3=/var/tmp/workstation_setup_private_$(date +%Y-%m-%d-%H:%M:%S).log
(
  # the purpose of this script is to house all macos workstation customizations requiring access to dotfiles_private
  echo "first, check that we are authenticated to password manager."
  op vault list > /dev/null || ( echo "Not logged into password manager; quitting" && exit 1)

  # now we can install any private repos with private ssh key
  # load personal ssh key if necessary
  if ! ssh-add -l | grep -q "/.ssh/id_rsa_personal\ ("; then
    (umask 177
    op item get id_rsa_personal --field notesPlain | sed 's/"//g' > ~/.ssh/id_rsa_personal
    )
    op item get id_rsa_personal --field Passphrase | pbcopy
    ssh-add -t 36000 -k ~/.ssh/id_rsa_personal
    rm -f ~/.ssh/id_rsa_personal
  fi
  private_repos="git@github.com:kr3cj/dotfiles_private.git"
  for private_repo in ${private_repos}; do
    source "${HOME}/.homesick/repos/homeshick/homeshick.sh"
    if homeshick list | grep -q ${private_repo}; then
      # must trim long git URIs to just repo name
      homeshick --batch pull "$(echo "${private_repo/*\//}" | sed -e "s/\.git$//")"
    else
      homeshick --batch clone ${private_repo}
    fi
    homeshick --force link
  done

  asdf install
  # heptio-authenticator-aws, aws-iam-authenticator, kubesec, minikube, python, ruby, trerraform, terragrunt, vault

  # install helm plugin for Visual Studio Code
  # manually add asdf pat
  for plugin1 in \
   lrills/helm-unittest \
   databus23/helm-diff \
   aslafy-z/helm-git ; do
     ~/.asdf/shims/helm plugin install https://github.com/${plugin1}
  done

  # mas is a CLI for AppStore installs/updates
  if [[ ${GHA_CI_RUN} != true ]]; then
    echo "Prepare to sign into \"App Store.app\" manually..."
    op item get Apple --field password | pbcopy
    # mas signin apple@${CUSTOM_HOME_DOMAIN} # disabled on macos 10.15.x+
    open -a "App Store"

    # Alfred v1.2 :( ; moved to brew cask installs below
    # mas install 405843582
    # Xcode
    # mas install 497799835
    # CopyClip
    mas install 595191960
    # Microsoft Remote Desktop 10.x
    mas install 1295203466
    # Magnet
    mas install 441258766
    # manual
    echo "give magnet accessibility privileges in system prefs, sec and privacy, privacy tab"
  fi
  # TODO: Create Dock shortcut to "/System/Library/CoreServices/Screen Sharing.app"


  if [[ ${GHA_CI_RUN} != true ]]; then
    # iterm2 customizations
    # Specify the preferences directory
    # defaults write com.googlecode.iterm2.plist PrefsCustomFolder -string \
      "~/.homesick/repos/dotfiles_private/iterm2/"
    # Tell iTerm2 to use the custom preferences in the directory
    # defaults write com.googlecode.iterm2.plist LoadPrefsFromCustomFolder -bool true

    # install java; TODO: move to work_setup.sh
    # brew tap homebrew/cask-versions
    # brew cask install java11
    # setup build system credentials; TODO: cache username/password?
    # $(brew --prefix docker)/bin/docker login ${CUSTOM_WORK_JFROG_SUBDOMAIN}.jfrog.io

    ### general macos customizations ###
    # first, backup the current defaults
    defaults read > ~/.macos_defaults_original_$(hostname)_$(/bin/date +%Y-%m-%d).json
    source "${HOME}/.homesick/repos/homeshick/homeshick.sh"
    homeshick track dotfiles_private ~/.macos_defaults_original_$(hostname)_$(/bin/date +%Y-%m-%d).json
    # FIX: second, load customizations https://github.com/mathiasbynens/dotfiles/blob/master/.macos
    # zsh ~/.macos_sane_defaults
    # Disable user interface sounds (screnshots, emptying trash)
    # defaults write com.apple.systemsound "com.apple.sound.uiaudio.enabled" -int 0
    # TODO: add iterm.app to "System Preferences > Security & Privacy > Privacy > Full Disk Access"
    echo "Give Full Disk Access permission to iTerm.app"
  fi

  if [[ ${GHA_CI_RUN} != true ]]; then
    # Run python code to checkout all repositories
    cd ~/build
    # git clone asottile/all-repos
    # cd all-repos
  fi

  # close out logging
) 2>&1 | tee -a ${LOG3}

echo "Checking for and running \"~/.work_setup.sh\"."
[[ -x ~/.work_setup.sh ]] && ~/.work_setup.sh
