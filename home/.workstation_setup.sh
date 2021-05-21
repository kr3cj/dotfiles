#!/usr/bin/env bash
set +x
LOG2=/var/tmp/workstation_setup_$(date +%Y-%m-%d).log
(
# the purpose of this script is to house all initial workstation customizations in linux or macos

if [[ ${TRAVIS_CI_RUN} != true ]]; then
  echo -e "\nSystem looks new. Press any key to start installing workstation software."
  read -n 1 -s
fi

export IS_MACOS="false"
export IS_LINUX="false"
case "$(uname)" in
  Darwin)
    IS_MACOS="true" ;;
  Linux)
    IS_LINUX="true" ;;
  *)
    echo "Unable to determine linux or macos" ;;
esac

# only proceed for linux workstations, not servers
if [[ ${TRAVIS_CI_RUN} != true ]]; then
  if [[ ${IS_LINUX} == true ]] && [[ ! -d /usr/share/xsessions ]]; then
    echo "Quitting workfstation setup on what appears to be a linux server"
    exit 0
  fi
fi

echo "Need sudo password to setup passwdless sudo"
if ! sudo grep -q $(whoami) /etc/sudoers && [[ ${TRAVIS_CI_RUN} != true ]]; then
  sudo bash -c "echo \"$(whoami) ALL=(ALL) NOPASSWD: ALL\" >> /etc/sudoers"
fi

# TODO: requires macos permission
# upgrade software Fridays at 10am
if ! $(crontab -l | grep -q workstation_update) ; then
  # FIX: crontab: tmp/tmp.55269: Operation not permitted
  (crontab -l 2>/dev/null; echo "0 10 * * 5 ~/.workstation_update.sh") | crontab -
fi

# install software on macos
if ${IS_MACOS} && ! hash mas 2>/dev/null ; then
  echo "Configuring macos. This will take an hour or so."
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
  brew install ed
  brew install findutils
  brew install gawk
  brew install gnu-indent
  brew install gnu-sed
  brew install gnu-tar
  brew install gnu-which
  brew install gnutls
  brew install grep
  brew install gzip
  brew install screen
  brew install watch
  brew install wdiff
  brew install wget
  brew install gnupg
  brew install gnupg2
  echo "install newer utilities than macos provides"
  brew install bash
  sudo /usr/local/opt/gnu-sed/libexec/gnubin/sed -i.bak "s/\/bin\/bash/\/usr\/local\/bin\/bash\\n\/bin\/bash/g" /etc/shells
  chsh -s /usr/local/bin/bash
  /usr/local/bin/bash

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
  brew install vim
  brew install tcpdump
  # brew install macvim --with-override-system-vim --custom-system-icons
  # brew link --overwrite macvim
  # brew linkapps macvim
  # brew install zsh
  # echo "install perl"
  # brew tap homebrew/versions
  # brew install perl518
  echo "install python"
  # https://docs.python-guide.org/starting/install3/osx/
  brew install python@3.8
  # pip3 install --upgrade distribute
  # pip3 install --upgrade pip
  # pip3 install pylint virtualenv yq==2.2.0

  echo "install some extra utility packages for me"
  brew install bash-completion certigo cfssl dos2unix gnu-getopt jid pstree step tree
  brew tap wallix/awless; brew install awless
  echo "install extra tools that I like"
  brew install \
    ack aria2 mas mtr nmap tmux reattach-to-user-namespace \
    ansible octant node rbenv ruby ruby-build \
    awscli hub packer hey siege tfenv travis vault maven zoom
    # openshift-cli fleetctl; aria2=torrent_client(aria2c); android-platform-tools; android-file-transfer
    # load testing clients: hey siege artillery gauntlet

  # create folder for repos before checking out private repo
  [[ -d ~/build/github ]] || mkdir -pv ~/build/github

  # install awscli session-manager-plugin
  (
    cd ~/build
    curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/mac/sessionmanager-bundle.zip" \
     -o "sessionmanager-bundle.zip"
    unzip sessionmanager-bundle.zip
    sudo ./sessionmanager-bundle/install -i /usr/local/sessionmanagerplugin \
     -b /usr/local/bin/session-manager-plugin
    ./sessionmanager-bundle/install -h
    rm -rf ./sessionmanager-bundle ./sessionmanager-bundle.zip
    # to uninstall, run:
    # sudo rm -rf /usr/local/sessionmanagerplugin
    # sudo rm /usr/local/bin/session-manager-plugin
  )

  # tmux plugins
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  # FIX: error connecting to /tmp//tmux-501/default (No such file or directory)
  tmux source ~/.tmux.conf
  ~/.tmux/plugins/tpm/bin/install_plugins

  sudo rm -rf /Applications/{iMovie.app,GarageBand.app,Pages.app,Numbers.app}

  cd ~/build/github
  for repo1 in \
   helm/charts \
   cleanbrowsing/dnsperftest \
   DataDog/datadog-serverless-functions \
   DataDog/Miscellany \
   ; do
    git clone https://github.com/${repo1}.git
  done

  # liquidprompt customizations deferred until merges are made for:
  #  bschwedler:feature/kubernetes-context and pull/476
  # brew install [--HEAD] liquidprompt
  brew install liquidprompt
  # standard customizations already tracked by dotfiles via ~/.liquidpromptrc

  # install main apps into user Applications to avoid admin permission requirements for upgrades
  HOMEBREW_CASK_OPTS="--appdir=~/Applications"
  # FIX: failed to download beyond-compare due to cert problem with curl
  brew install --cask ${HOMEBREW_CASK_OPTS} \
    alfred slack spotify gimp github google-backup-and-sync iterm2 \
    firefox keystore-explorer balenaetcher visual-studio-code
    # keybase private-internet-access; etcher is a usb flash utility

  # brew install --cask intellij-idea goland
  # input license for intellij, then goland should detect it, then remove intellij?

  # install brave separately. if already installed it won't break the rest
  brew install --cask brave-browser

  # broken up into separate commands to avoid 10 minute travis build timeout
  brew install --cask wireshark
  # TODO: disable updates in docker so brew update can manage it, disable experimental features
  brew install --cask docker
  open -a "Docker"
  # virtualbox

  # TODO: use openvpn to connect to PIA via CLI
  #  https://helpdesk.privateinternetaccess.com/hc/en-us/articles/219437987-Installing-OpenVPN-PIA-on-MacOS
  # old google-photos-backup available at
  #  https://onedrive.live.com/?authkey=%21AACjGt3FG05pkGM&cid=8E2F81FF61FCF79E&id=8E2F81FF61FCF79E%21104613&parId=8E2F81FF61FCF79E%2187733&o=OneUp
  # brew install Caskroom/cask/pycharm-ce
  HOMEBREW_CASK_OPTS=""

  # TODO: when etcher-cli comes out, install it from homebrew

  # https://developer.mozilla.org/en-US/docs/Mozilla/Command_Line_Options
  echo "Lock down firefox about:config
    browser.search.defaultenginename
  "

    # install atom editor plugins
  # apm install auto-update-packages open-terminal-here minimap language-hcl \
  #   markdown-toc terraform-fmt \
  #   language-groovy file-icons tree-view-git-status highlight-selected git-plus \
  #   linter linter-ui-default intentions busy-signal \
  #   linter-checkbashisms linter-terraform-syntax language-terraform
  # language-terraform autocomplete-bash-builtins terminal-plus

  # install visual studio code extensions (weird hack required)
    # bierner.markdown-preview-github-styles \
    # brendandburns.vs-kubernetes \
    # codezombiech.gitignore \
    # CoenraadS.bracket-pair-colorizer \
    # donjayamanne.git-extension-pack \
    # donjayamanne.githist\ory \
    # eamodio.gitlens \
    # erd0s.terraform-autocomplete \
    # felixrieseberg.vsc-travis-ci-status \
    # ipedrazas.kubernetes-snippets \
    # KnisterPeter.vscode-github \
    # mauve.terraform \
    # ms-python.python \
    # ms-vscode.go \
    # PeterJausovec.vscode-docker \
    # technosophos.vscode-helm \
    # timonwong.shellcheck \
  cat << EOF > /var/tmp/vscode_installs.sh
#!$(which bash)
EOF
  for extension1 in \
    eamodio.gitlens \
    GitHub.vscode-pull-request-github \
    hashicorp.terraform \
    ms-python.python \
    timonwong.shellcheck \
    ; do
    echo "code --install-extension ${extension1} --verbose" >> /var/tmp/vscode_installs.sh
  done
  bash /var/tmp/vscode_installs.sh && rm -v /var/tmp/vscode_installs.sh
  echo "Grab Personal Access Token from GitHub; put into vscode"

  # install helm client
  # additional hackery for brew dependencies. also, must install helm after kubernetes?
  # brew install kubernetes-helm ; brew unlink kubernetes-helm #
  # asdf
  brew install asdf

  # install asdf tools
  # golang
  for asdf_plugin in argo eksctl golang helm helmfile jq kubectl kustomize \
      linkerd minikube nova octant pluto poetry python saml2aws sinker sops sopstool terraform \
      terraform-docs yq; do
    asdf plugin-add ${asdf_plugin}
  done
  asdf plugin-add octant https://github.com/looztra/asdf-octant

  # gce and gke stuff (https://cloud.google.com/sdk/docs/quickstart-mac-os-x)
  brew install golang
  go get golang.org/x/tools/cmd/godoc

  # prep for home nfs mount
  [[ -d ~/Documents/share1 ]] || mkdir ~/Documents/share1
  [[ -d ~/Pictures/share1 ]] || mkdir ~/Pictures/share1

  ### Rest requires bash v5+ and authenticated password manager cli for private dotfiles ###
  # brew install lastpass-cli
  brew install --cask 1password-cli
  if [[ ${TRAVIS_CI_RUN} != true ]]; then
    echo -e "\nTo continue, you must be authenticated to password manager cli: \
    op signin ${CUSTOM_HOME_PASSWD_MGR_ACCOUNT} \
    eval \$(op signin my) \
    Then start \"~/.workstation_setup_private.sh\"."
    read -n 1 -s
    # [[ -r ~/.workstation_setup_private.sh ]] && \
    #   /usr/local/bin/bash ~/.workstation_setup_private.sh
  else
    echo -e "\nInitial macos System setup completed."
  fi

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
    # lastpass
    # echo "For LastPass CLI, see https://github.com/lastpass/lastpass-cli/blob/master/README.md#debianubuntu"

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

    # TODO: create function for installing minikube, kubectl etc (in linux) with curl+chmod+mv commands
    # minikube_version=$(curl -s https://api.github.com/repos/kubernetes/minikube/releases/latest | jq -r '.tag_name')
    # curl -Lo minikube https://storage.googleapis.com/minikube/releases/${minikube_version}/minikube-darwin-amd64
    #   chmod -v +x minikube
    #   sudo mv -v minikube /usr/local/bin/

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

    [[ -x ~/.work_setup.sh ]] && ~/.work_setup.sh

  elif ${is_rhel} ; then
    echo "Configuring RHEL. This will take a few minutes."
    sudo yum install -y python-dev python3 tmux ack lastpass-cli git curl xclip aria2
  fi
  # pip
  sudo wget https://bootstrap.pypa.io/get-pip.py
  sudo python get-pip.py && rm get-pip.py
  sudo pip install --upgrade setuptools
  pip install awscli --upgrade --user
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

# close out logging
) 2>&1 | tee -a ${LOG2}
