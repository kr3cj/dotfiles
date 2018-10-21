#!/usr/bin/env bash
# the purpose of this script is to house all initial workstation customizations in linux or osx

if [[ ${TRAVIS_CI_RUN} != true ]]; then
  echo -e "\nSystem looks new. Press any key to start installing workstation software."
  read -n 1 -s
fi

export IS_OSX="false"
export IS_LINUX="false"
case "$(uname)" in
  Darwin)
    IS_OSX="true" ;;
  Linux)
    IS_LINUX="true" ;;
  *)
    echo "Unable to determine Linux or OSX" ;;
esac

# only proceed for Linux workstations, not servers
if [[ ${TRAVIS_CI_RUN} != true ]]; then
  if [[ ${IS_LINUX} == true ]] && [[ ! -d /usr/share/xsessions ]]; then
    echo "Quitting workfstation setup on what appears to be a linux server"
    exit 0
  fi
fi

if ! sudo grep -q $(whoami) /etc/sudoers && [[ ${TRAVIS_CI_RUN} != true ]]; then
  echo "Need sudo password to setup passwdless sudo"
  sudo bash -c "echo \"$(whoami) ALL=(ALL) NOPASSWD: ALL\" >> /etc/sudoers"
fi

# install software on osx
if ${IS_OSX} && ! hash mas 2>/dev/null ; then
  echo "Configuring OSX. This will take an hour or so."
  # see http://meng6.net/pages/computing/installing_and_configuring/installing_and_configuring_command-line_utilities/
  if ! hash brew 2>/dev/null ; then
    echo "Installing brew"
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi
  brew_options=" --default-names --with-default-names --with-gettext --override-system-vi \
    --override-system-vim --custom-system-icons"
  echo "install gnu core utilities"
  brew install coreutils
  echo "install utilities"
  brew install binutils
  brew install diffutils
  brew install ed --with-default-names
  # brew install findutils --with-default-names ## This will cause 'brew doctor' to issue warning: "Putting non-prefixed findutils in your path can cause python builds to fail."
  brew install findutils
  brew install gawk
  brew install gnu-indent --with-default-names
  brew install gnu-sed --with-default-names
  brew install gnu-tar --with-default-names
  brew install gnu-which --with-default-names
  brew install gnutls
  brew install grep --with-default-names
  brew install gzip
  brew install screen
  brew install watch
  brew install wdiff --with-gettext
  brew install wget
  brew install gnupg
  brew install gnupg2
  echo "install newer utilities than OSX provides"
  brew install bash
  # brew link --overwrite bash # OR #
  # prepend new shell to /etc/shells
  if [[ ${TRAVIS_CI_RUN} != true ]]; then # remove once osx images allow passwdless sudo
    sudo sed -i '/^\/bin\/bash$/i \/usr\/local\/bin\/bash' /etc/shells
    chsh -s /usr/local/bin/bash
  fi

  # brew install emacs
  # brew install --cocoa --srgb emacs ##
  # brew linkapps emacs
  brew install gdb  # gdb requires further actions to make it work. See `brew info gdb`.
  brew install guile
  brew install gpatch
  brew install m4
  brew install make
  brew install nano
  echo "install more newer utilities"
  brew install file-formula
  brew install git
  brew install less
  brew install openssh
  brew install rsync
  brew install svn
  brew install unzip
  brew install vim --override-system-vi
  brew install tcpdump
  # brew install macvim --with-override-system-vim --custom-system-icons
  # brew link --overwrite macvim
  # brew linkapps macvim
  # brew install zsh
  # echo "install perl"
  # brew tap homebrew/versions
  # brew install perl518
  echo "install python"
  # http://docs.python-guide.org/en/latest/starting/install3/osx/
  brew install python3
  # brew linkapps python
  echo "override python binaries"
  alias python="python3"
  alias pip="pip3"
  pip3 install --upgrade distribute
  pip3 install --upgrade pip
  pip install pylint virtualenv yq==2.2.0

  echo "install some extra utility packages for me"
  brew install dos2unix gnu-getopt jq pstree bash-completion
  echo "install extra tools that I like"
  brew install \
    ack aria2 mas mtr nmap tmux reattach-to-user-namespace \
    maven python3 ansible node rbenv ruby ruby-build \
    awscli hub packer siege terraform travis vault
    # openshift-cli fleetctl; aria2=torrent_client(aria2c)

  echo "install lastpass client"
  brew install lastpass-cli --with-pinentry
  lpass status > /dev/null || \
    DISPLAY=${DISPLAY:-:0} lpass login --trust lastpass@${CUSTOM_HOME_DOMAIN}

  # now we can install any private repos with private ssh key
  if [[ ${TRAVIS_CI_RUN} != true ]]; then
    # load personal ssh key if necessary
    if ! $(ssh-add -l | grep -q "/.ssh/id_rsa_personal\ ("); then
      (umask 177
      lpass show --field="Private Key" "Personal SSH Key" > ~/.ssh/id_rsa_personal
      )
      lpass show --field=Passphrase --clip "Personal SSH Key"
      ssh-add -t 36000 -k ~/.ssh/id_rsa_personal
      clear_clip
      rm -f ~/.ssh/id_rsa_personal
    fi
    private_repos="git@bitbucket.org:kr3cj/dotfiles_private.git"
    for private_repo in ${private_repos}; do
      if homeshick list | grep -q ${private_repo}; then
        # must trim long git URIs to just repo name
        homeshick --batch pull $(echo ${private_repo/*\//} | sed -e "s/\.git$//")
      else
        homeshick --batch clone ${private_repo}
      fi
      homeshick --force link
    done
  fi

  # tmux plugins
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  tmux source ~/.tmux.conf
  ~/.tmux/plugins/tpm/bin/install_plugins

  # liquidprompt customizations deferred until merges are made for:
  #  bschwedler:feature/kubernetes-context and pull/476
  # brew install [--HEAD] liquidprompt
  brew install liquidprompt
  # standard customizations already tracked by dotfiles via ~/.liquidpromptrc

  # mas is a CLI for AppStore installs/updates
if [[ ${TRAVIS_CI_RUN} != true ]]; then
    lpass show --password --clip "Apple" && \
      mas signin apple@${CUSTOM_HOME_DOMAIN}
    clear_clip
    mas install 405843582 # Alfred
    mas install 497799835 # Xcode
    mas install 595191960 # CopyClip
    mas install 1295203466 # Microsoft Remote Desktop 10.x
    mas install 441258766 # Magnet
  fi
  # TODO: Create Dock shortcut to "/System/Library/CoreServices/Screen Sharing.app"
  # TODO: give magnet accessibility privileges in system prefs, sec and privacy, privacy tab
  echo "Remove the following apps from showing in menu bar: Alfred, ?"
  if [[ ${TRAVIS_CI_RUN} != true ]]; then
    sudo rm -rf /Applications/{iMovie.app,GarageBand.app,Pages.app,Numbers.app}
  fi

  # finish xcode install?
  # xcode-select --install

  # puppet testing shtuff
  if [[ ${TRAVIS_CI_RUN} != true ]]; then
    sudo gem install bundler
  fi

  # install main apps into Applications
  HOMEBREW_CASK_OPTS="--appdir=/Applications"
  # TODO: disable updates in docker so brew update can manage it, disable experimental features
  brew cask install \
    atom slack spotify gimp google-backup-and-sync iterm2 vagrant \
    beyond-compare firefox keystore-explorer private-internet-access \
    wireshark visual-studio-code

  # broken up into separate commands to avoid 10 minute travis build timeout
  brew cask install docker
  brew install docker-compose android-file-transfer

    # android-platform-tools
    # google-
    # virtualbox visual-studio-code
  # TODO: use openvpn to connect to PIA via CLI
  #  https://helpdesk.privateinternetaccess.com/hc/en-us/articles/219437987-Installing-OpenVPN-PIA-on-MacOS
  # old google-photos-backup available at
  #  https://onedrive.live.com/?authkey=%21AACjGt3FG05pkGM&cid=8E2F81FF61FCF79E&id=8E2F81FF61FCF79E%21104613&parId=8E2F81FF61FCF79E%2187733&o=OneUp
  # brew install Caskroom/cask/pycharm-ce
  HOMEBREW_CASK_OPTS=""

  # TODO: when etcher-cli comes out, install it from homebrew

  # https://developer.mozilla.org/en-US/docs/Mozilla/Command_Line_Options
  echo "Lock down firefox about:config
    network.trr.mode=2
    network.trr.uri=https://mozilla.cloudflare-dns.com/dns-query
    browser.search.defaultenginename
  "

  if [[ ${TRAVIS_CI_RUN} != true ]]; then
    # iterm2 customizations
    # Specify the preferences directory
    defaults write com.googlecode.iterm2.plist PrefsCustomFolder -string \
      "~/.homesick/repos/dotfiles_private/iterm2/"
    # Tell iTerm2 to use the custom preferences in the directory
    defaults write com.googlecode.iterm2.plist LoadPrefsFromCustomFolder -bool true

    # install java8
    brew tap caskroom/versions
    brew cask install java8
    # setup build system credentials
    docker login ${CUSTOM_WORK_JFROG_SUBDOMAIN}.jfrog.io

    ### general osx customizations ###
    # first, backup the current defaults
    defaults read > ~/.osx_defaults_original_$(date --rfc-3339=seconds).json
    source "${HOME}/.homesick/repos/homeshick/homeshick.sh"
    homeshick track dotfiles_private ~/osx_defaults_original_$(date --rfc-3339=seconds).json
    # second, load customizations https://github.com/mathiasbynens/dotfiles/blob/master/.macos
    bash ~/.osx_customizations.json
  fi

  # install atom editor plugins
  apm install auto-update-packages open-terminal-here minimap language-hcl \
    markdown-toc terraform-fmt \
    language-groovy file-icons tree-view-git-status highlight-selected git-plus \
    linter linter-ui-default intentions busy-signal \
    linter-checkbashisms linter-terraform-syntax language-terraform
  # language-terraform autocomplete-bash-builtins terminal-plus

  # install visual studio code extensions (weird hack required)
  cat << EOF > /var/tmp/vscode_installs.sh
#!$(which bash)
EOF
  for extension1 in \
    bierner.markdown-preview-github-styles \
    brendandburns.vs-kubernetes \
    codezombiech.gitignore \
    CoenraadS.bracket-pair-colorizer \
    donjayamanne.git-extension-pack \
    donjayamanne.githistory \
    eamodio.gitlens \
    erd0s.terraform-autocomplete \
    felixrieseberg.vsc-travis-ci-status \
    ipedrazas.kubernetes-snippets \
    KnisterPeter.vscode-github \
    mauve.terraform \
    ms-python.python \
    ms-vscode.go \
    PeterJausovec.vscode-docker \
    technosophos.vscode-helm \
    ; do
    echo "code --install-extension ${extension1} --verbose" >> /var/tmp/vscode_installs.sh
  done
  bash /var/tmp/vscode_installs.sh && rm -v /var/tmp/vscode_installs.sh
  echo "Grab Personal Access Token from GitHub; put into vscode"
  cat << EOF >> ${HOME}/Library/Application Support/Code/User/settings.json
  {
    "files.autoSave": "afterDelay",
    "workbench.startupEditor": "none"
  }
  EOF

  # gce and gke stuff (https://cloud.google.com/sdk/docs/quickstart-mac-os-x)
  brew install go
  go get golang.org/x/tools/cmd/godoc
  # brew cask install google-cloud-sdk
  # gcloud components install kubectl -q
  # gcloud init
  # gcloud auth list
  # gcloud config list

  # must install helm after kubernetes?
  # this will install 2 kubernetes clients (gcloud's and brew's)
  brew install kubernetes-helm kubernetes-cli kops kubectx

  # install helm plugin for Visual Studio Code
  helm init
  helm plugin install https://github.com/technosophos/helm-template
  # minikube client (all-in-one k8s)
  # TODO: create function for installing minikube, kubectl etc (in linux) with curl+chmod+mv commands
  # minikube_version=$(curl -s https://api.github.com/repos/kubernetes/minikube/releases/latest | jq -r '.tag_name')
  # curl -Lo minikube https://storage.googleapis.com/minikube/releases/${minikube_version}/minikube-darwin-amd64
  #   chmod -v +x minikube
  #   sudo mv -v minikube /usr/local/bin/

  # prep for home nfs mount
  [[ -d ~/Documents/share1 ]] || mkdir ~/Documents/share1
  [[ -d ~/Pictures/share1 ]] || mkdir ~/Pictures/share1

if [[ ${TRAVIS_CI_RUN} != true ]]; then

  # Run python code to checkout all repositories
  [[ -d ~/build ]] || mkdir ~/build
  cd ~/build
  # git clone asottile/all-repos
  # cd all-repos


fi

# install software on linux
if ${IS_LINUX} && ! hash packer 2>/dev/null ; then
  is_debian="false"
  is_rhel="false"

  if [[ -f /etc/redhat-release ]] ; then
    is_rhel="true"
  elif [[ -f /etc/os-release ]] ; then
    is_debian="true"
  else
    echo "Unable to determine unix distro."
  fi
  if ${is_debian} ; then
    echo "Configuring Debian. This will take a few minutes."
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl git software-properties-common
    sudo apt-get install -y python-dev python3 tmux ack-grep jq xclip aria2
    # pip
    sudo wget https://bootstrap.pypa.io/get-pip.py
    sudo python get-pip.py && rm get-pip.py
    sudo pip install --upgrade setuptools
    # lastpass
    echo "For LastPass CLI, see https://github.com/lastpass/lastpass-cli/blob/master/README.md#debianubuntu"

    # if you must install docker on a full blown OS
    sudo apt-get update
    sudo apt-get install -y docker-ce
    sudo /usr/bin/systemctl enable docker
    sudo groupadd docker || true
    sudo usermod -aG docker ${USER}

    # kubectl (TODO: move to shared function)
    wget -O kubectl https://storage.googleapis.com/kubernetes-release/release/$(curl -s \
      https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
    chmod +x ./kubectl
    sudo mv -v ./kubectl /usr/local/bin/
    # kops (TODO: move to shared function)
    wget -O kops https://github.com/kubernetes/kops/releases/download/$(curl -s \
      https://api.github.com/repos/kubernetes/kops/releases/latest \
      | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64
    chmod +x ./kops
    sudo mv -v ./kops /usr/local/bin/
    # helm (TODO: move to shared function)
    curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash

    # terraform (TODO: move to shared function)
    wget -O terraform.zip $(echo "https://releases.hashicorp.com/terraform/$(curl -s \
      https://checkpoint-api.hashicorp.com/v1/check/terraform | jq -r -M '.current_version')/terraform_$(curl -s \
      https://checkpoint-api.hashicorp.com/v1/check/terraform | jq -r -M '.current_version')_linux_amd64.zip")
    unzip terraform.zip -d /usr/local
    chmod +x ./terraform
    sudo mv -v ./terraform /usr/local/bin/

    # packer (TODO: move to shared function)
    wget -O packer.zip $(echo "https://releases.hashicorp.com/packer/$(curl -s \
      https://checkpoint-api.hashicorp.com/v1/check/packer| jq -r -M '.current_version')/packer$(curl -s \
      https://checkpoint-api.hashicorp.com/v1/check/packer| jq -r -M '.current_version')_linux_amd64.zip")
    unzip packer.zip -d /usr/local
    chmod +x ./packer
    sudo mv -v ./packer /usr/local/bin/

    # docker-compose (TODO: move to shared function)
    curl -L https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r '.tag_name')/run.sh > \
      /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    docker-compose --version

  elif ${is_rhel} ; then
    echo "Configuring RHEL. This will take a few minutes."
    sudo yum install -y python-dev python3 tmux ack lastpass-cli git curl xclip aria2
    # pip
    sudo wget https://bootstrap.pypa.io/get-pip.py
    sudo python get-pip.py && rm get-pip.py
    sudo pip install --upgrade setuptools
  fi
  # install liquidprompt for linux
  cd
  git clone https://github.com/nojhan/liquidprompt.git
  source liquidprompt/liquidprompt
  # install the rest via pip
    # sudo easy_install pip
  # vagrant, packer, python2+3, ansible, ruby, virtualbox?, gems, docker-ce, fleetctl, java, dos2unix
  # aws and gce/gke CLIs will be installed via ~/.bashrc.d/*
  sudo pip install PyYAML jinja2 paramiko ansible packer vagrant markupsafe
fi

# upgrade software Fridays at 10am
if ! $(crontab -l | grep -q workstation_update) ; then
  (crontab -l 2>/dev/null; echo "0 10 * * 5 ~/.workstation_update.sh") | crontab -
fi
