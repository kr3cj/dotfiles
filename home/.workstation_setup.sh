#!/bin/zsh
LOG2=/var/tmp/workstation_setup_$(date +%Y-%m-%d-%H:%M:%S).log
(
# the purpose of this script is to house all initial workstation customizations in linux or macos

if [[ ${GHA_CI_RUN} != true ]]; then
  /usr/bin/read -s -k "?System looks new. Press any key to start installing workstation software."
fi

export IS_MACOS="false"
export IS_LINUX="false"
export IS_ARM="false"
case "$(uname)" in
  Darwin)
    IS_MACOS="true" ;;
  Linux)
    IS_LINUX="true" ;;
  *)
    echo "Unable to determine linux or macos" ;;
esac
case "$(uname -m)" in
  arm64)
    export IS_ARM="true"
esac

# only proceed for workstations, not servers
if [[ ${GHA_CI_RUN} != true ]]; then
  if [[ ${IS_LINUX} == true ]] && [[ ! -d /usr/share/xsessions ]]; then
    echo "Quitting workfstation setup on what appears to be a linux server"
    exit 0
  fi
fi

# echo "Need sudo password to setup passwdless sudo"
# if ! sudo grep -q $(whoami) /etc/sudoers && [[ ${GHA_CI_RUN} != true ]]; then
#   sudo bash -c "echo \"$(whoami) ALL=(ALL) NOPASSWD: ALL\" >> /etc/sudoers"
# fi

echo -e "\nInstalling Homebrew..."
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
BREWBIN_PATH="/usr/local/bin/brew"
[[ "$(uname -m)" == "arm64" ]] && BREWBIN_PATH="/opt/homebrew/bin/brew"
BASE_PATH="$(${BREWBIN_PATH} --prefix)"
export PATH="${BASE_PATH}/bin:${PATH}"
echo -e "\nInstalling brew packages..."
brew bundle --file ~/.homesick/repos/dotfiles/Brewfile

# TODO: requires macos permission
# upgrade software Fridays at 10am
if ! $(crontab -l | grep -q workstation_update) ; then
  # FIX: crontab: tmp/tmp.55269: Operation not permitted
  (crontab -l 2>/dev/null; echo "0 10 * * 5 ~/.workstation_update.sh") | crontab -
fi

# install software on macos
if ${IS_MACOS}; then
  echo "Configuring macos. This will take an hour or so."
  # see http://meng6.net/pages/computing/installing_and_configuring/installing_and_configuring_command-line_utilities/
  brew_options=" --default-names --with-default-names --with-gettext --override-system-vi \
    --override-system-vim --custom-system-icons"
  # install main apps into user Applications to avoid admin permission requirements for upgrades
  brew bundle --file ~/.homesick/repos/dotfiles/Brewfile
  HOMEBREW_CASK_OPTS=""

  echo "Configuring new brew packages"

  yes | $(brew --prefix)/opt/fzf/install

  # liquidprompt customizations deferred until merges are made for:
  #  bschwedler:feature/kubernetes-context and pull/476
  # standard customizations already tracked by dotfiles via ~/.liquidpromptrc

  # input license for intellij, then goland should detect it, then remove intellij?

  # install asdf tools
  export PATH="${BASE_PATH}/opt/asdf/libexec/bin/asdf:${LOG_NAME}/.asdf/shims:${PATH}"
  # golang
  for asdf_plugin in 1password-cli argo awscli eksctl golang grpcurl helm helmfile jq k9s krew \
   kubectl kustomize minikube nova pluto poetry python saml2aws sinker sops sopstool starship \
   steampipe terraform terraform-docs viddy yq; do
   # kops linkerd minikube octant
    asdf plugin-add ${asdf_plugin}
  done

  kubectl krew install get-all

  # pip3 install --upgrade distribute
  # pip3 install --upgrade pip
  # pip3 install pylint virtualenv yq==2.2.0

  # tmux plugins
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  # FIX: error connecting to /tmp//tmux-501/default (No such file or directory)
  tmux source ~/.tmux.conf
  ~/.tmux/plugins/tpm/bin/install_plugins

  /usr/bin/read -s -k "?Push enter when sudo is auth'd by corporate software..."
  sudo -l || return 1
  echo "Remove this stuff that I don't use on macos"
  sudo rm -rf /Applications/{iMovie.app,GarageBand.app,Pages.app,Numbers.app}

  # docker/colima
  # mkdir -p ~/.docker
  /opt/homebrew/bin/colima start

  # TODO: use openvpn to connect to Mullvad via CLI
  #  https://helpdesk.privateinternetaccess.com/hc/en-us/articles/219437987-Installing-OpenVPN-PIA-on-MacOS
  # old google-photos-backup available at
  #  https://onedrive.live.com/?authkey=%21AACjGt3FG05pkGM&cid=8E2F81FF61FCF79E&id=8E2F81FF61FCF79E%21104613&parId=8E2F81FF61FCF79E%2187733&o=OneUp

    # install atom editor plugins
  # apm install auto-update-packages open-terminal-here minimap language-hcl \
  #   markdown-toc terraform-fmt \
  #   language-groovy file-icons tree-view-git-status highlight-selected git-plus \
  #   linter linter-ui-default intentions busy-signal \
  #   linter-checkbashisms linter-terraform-syntax language-terraform
  # language-terraform autocomplete-bash-builtins terminal-plus

  # install visual studio code extensions (weird hack required)
  cat << EOF > /var/tmp/vscode_installs.sh
#!$(which bash)
EOF
  for extension1 in \
    DavidAnson.vscode-markdownlint \
    eamodio.gitlens \
    GitHub.vscode-pull-request-github \
    hashicorp.terraform \
    moshfeu.compare-folders \
    ms-python.python \
    redhat.vscode-yaml \
    timonwong.shellcheck \
    ; do
    echo "code --install-extension ${extension1}" >> /var/tmp/vscode_installs.sh
  done
  bash /var/tmp/vscode_installs.sh && rm -v /var/tmp/vscode_installs.sh
  echo "Grab Personal Access Token from GitHub; put into vscode"

  # gce and gke stuff (https://cloud.google.com/sdk/docs/quickstart-mac-os-x)
  # TODO: fix for newer versions
  # go get golang.org/x/tools/cmd/godoc

  /usr/bin/read -s -k "?Push enter when sudo is auth'd by corporate software..."
  sudo -l || return 1
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

  # create folder for repos before checking out private repo
  [[ -d ~/build/github ]] || mkdir -pv ~/build/github
  cd ~/build/github
  for repo1 in \
   helm/charts \
   cleanbrowsing/dnsperftest \
   DataDog/datadog-serverless-functions \
   DataDog/Miscellany \
   ; do
    git clone https://github.com/${repo1}.git
  done
  # prep for home nfs mount
  [[ -d ~/Documents/share1 ]] || mkdir ~/Documents/share1
  [[ -d ~/Pictures/share1 ]] || mkdir ~/Pictures/share1

  ### Rest requires bash v5+ and authenticated password manager cli for private dotfiles ###
  if [[ ${GHA_CI_RUN} != true ]]; then
    # secret zero
    echo -e "\nTo continue, you must be authenticated to password manager cli: \
    op account add --address ${CUSTOM_HOME_PASSWD_MGR_ACCOUNT[1]} --email ${CUSTOM_HOME_PASSWD_MGR_ACCOUNT[2]}
    eval \$(op signin) \
    Then start \"~/.workstation_setup_private.sh\"."
    /usr/bin/read -s -k "?Press any key to continue."
    # [[ -r ~/.workstation_setup_private.sh ]] && \
    #   zsh ~/.workstation_setup_private.sh
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
