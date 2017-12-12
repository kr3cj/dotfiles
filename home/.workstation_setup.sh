#!/bin/bash
# the purpose of this script is to house all initial workstation customizations in linux or osx

# get my bearings
ip_address=""
is_debian="false"
is_rhel="false"
at_work="false"
brew_options=" --default-names --with-default-names --with-gettext --override-system-vi \
  --override-system-vim --custom-system-icons"

if ${IS_OSX} ; then
  ip_address=$(/sbin/ifconfig en0 | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}')
elif ${IS_LINUX} ; then
  # only proceed for Linux workstations
  if [[ $(runlevel | cut -d ' ' -f2) -le 3 ]] ; then
    echo "Quitting workstation setup on what appears to be a server"
    exit 0
  fi
  ip_address=$(ip addr show | grep 'inet ' | grep -v 127 | head -n1 | awk '{print $2}' | cut -d/ -f1)
  if [[ -f /etc/redhat-release ]] ; then
    is_rhel="true"
  elif [[ -f /etc/os-version ]] ; then
    is_debian="true"
  fi
else
  echo "Unable to determine unix distro."
fi

( [[ ${ip_address} =~ "${CUSTOM_WORK_SUBNET}.49." ]] || [[ ${ip_address} =~ "${CUSTOM_WORK_SUBNET}.200." ]] \
  || [[ ${ip_address} =~ "${CUSTOM_WORK_SUBNET}.67." ]] ) && ${at_work}

# setup passwdless sudo
echo "Need sudo password to setup passwdless sudo"
if ! sudo grep -q $(whoami) /etc/sudoers ; then
  sudo bash -c "echo \"$(whoami) ALL=(ALL) NOPASSWD: ALL\" >> /etc/sudoers"
fi

if ${IS_OSX} && ! hash mas 2>/dev/null ; then
  echo "Configuring OSX. This will take an hour or so."
  # see http://meng6.net/pages/computing/installing_and_configuring/installing_and_configuring_command-line_utilities/
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
  brew link --overwrite bash
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
  # brew install macvim --with-override-system-vim --custom-system-icons
  # brew link --overwrite macvim
  # brew linkapps macvim
  # brew install zsh
  # echo "install perl"
  # brew tap homebrew/versions
  # brew install perl518
  echo "install python"
  brew install python
  # brew linkapps python
  pip install --upgrade pip setuptools

  echo "install some extra utility packages for me"
  brew install dos2unix gnu-getopt
  echo "install extra tools that I like"
  brew install \
    ack aria2 mas mtr nmap \
    go maven \
    python3 ansible \
    rbenv ruby ruby-build \
    awscli docker docker-compose fleetctl openshift-cli packer terraform

  # mas is a CLI for AppStore installs/updates
  # TODO: move lpass setup before this step to achieve automatic password prefill
  mas signin ${CUSTOM_WORK_EMAIL} # "$(lpass show --password 'Apple (work)')"
  mas install 405843582 # Alfred (1.2)
  mas install 497799835 # Xcode
  mas install 595191960 # CopyClip (1.9)
  mas install 715768417 # Microsoft Remote Desktop (8.0.27246)
  # mas install 417375580 # BetterSnapTool (1.7)
  # TODO: f.lux
  sudo rm -rf /Applications/{iMovie.app,GarageBand.app,Pages.app,Numbers.app}

  # puppet testing shtuff
  sudo gem install bundler

  # install main apps into Applications
  HOMEBREW_CASK_OPTS="--appdir=/Applications"
  brew cask install \
    slack spotify gimp google-photos-backup iterm2 android-file-transfer android-platform-tools \
    atom iterm2 vagrant virtualbox jq vault \
    keystore-explorer \
    google-cloud-sdk beyond-compare visual-studio-code firefox
  # brew install Caskroom/cask/pycharm-ce
  HOMEBREW_CASK_OPTS=""

  # install java8
  brew tap caskroom/versions
  brew cask install java8
  # setup build system credentials
  docker login artifactory.ecovate.com
  # TODO: populate credential files for builds
  (umask 077 ; mkdir ~/.ivy2 ~/.m2 ; touch ~/.ivy2/{auth.properties,ivysettings.xml} ~/.m2/settings.xml)
  # TODO: .pgpass, npmrc, .vnc/passwd, .ant/settings.xml, .jspm/config

  # install atom editor plugins
  apm install auto-update-packages terminal-plus open-terminal-here minimap language-hcl \
    autocomplete-bash-builtins markdown-toc terraform-fmt \
    language-groovy file-icons tree-view-git-status highlight-selected git-plus \
    linter linter-ui-default intentions busy-signal
    linter-checkbashisms linter-terraform-syntax
  # language-terraform

  # install visual studio code extensions
  for i in technosophos.vscode-helm brendandburns.vs-kubernetes PeterJausovec.vscode-docker; do
    code --install-extension ${i}
  done
  # move visual-studio-code overrides into dotfiles?
  # cat << EOF >> $HOME/Library/Application Support/Code/User/settings.json
  # {
  #   "files.autoSave": "afterDelay",
  #   "workbench.startupEditor": "none"
  # }
  #


  # install cisco vpn client
  echo "Please install the \"Cisco AnyConnect Secure Mobility Client\""
  cat << EOF | sudo tee -a /opt/cisco/anyconnect/profile/Profile.xml
<AnyConnectProfile xmlns="http://schemas.xmlsoap.org/encoding/">
  <ServerList>
    <HostEntry>
      <HostName>readytalk</HostName>
      <HostAddress>${CUSTOM_WORK_VPN_RT}</HostAddress>
    </HostEntry>
    <HostEntry>
      <HostName>pgi</HostName>
      <HostAddress>${CUSTOM_WORK_VPN_PGI[0]}</HostAddress>
      <BackupServerList>
        <HostAddress>${CUSTOM_WORK_VPN_PGI[1]}</HostAddress>
        <HostAddress>${CUSTOM_WORK_VPN_PGI[2]}</HostAddress>
      </BackupServerList>
    </HostEntry>
  </ServerList>
</AnyConnectProfile>
EOF

  # python stuff
  sudo easy_install pip
  pip install pylint virtualenv

  # gce and gke stuff (https://cloud.google.com/sdk/docs/quickstart-mac-os-x)
  go get golang.org/x/tools/cmd/godoc
  gcloud components install kubectl -q
  gcloud init
  gcloud auth list
  gcloud config list

  # must install helm after kubernetes?
  # this will install 2 kubernetes clients (gcloud's and brew's)
  brew install kubernetes-helm kubernetes-cli kops

  # install helm plugin for Visual Studio Code
  helm plugin install https://github.com/technosophos/helm-template
  helm init
  # minikube client (all-in-one k8s)
  # TODO: create function for installing minikube, kubectl etc (in linux) with curl+chmod+mv commands
  minikube_version=$(curl -s https://api.github.com/repos/kubernetes/minikube/releases/latest | jq -r '.tag_name')
  curl -Lo minikube https://storage.googleapis.com/minikube/releases/${minikube_version}/minikube-darwin-amd64
    chmod -v +x minikube
    sudo mv -v minikube /usr/local/bin/

  # docker for mac
  # wget https://download.docker.com/mac/stable/Docker.dmg
  # sudo hdiutil attach Docker.img
  # sudo installer -package /Volumes/Docker/Docker.pkg -target /Applications
  # sudo hdiutil detach "/Volumes/Docker/"

  # prep for home nfs mount
  mkdir ~/Documents/share1
  mkdir ~/Pictures/share1

  ### general osx customizations from https://github.com/mathiasbynens/dotfiles/blob/master/.macos ###
  # first, backup the current defaults
  defaults read > ~/osx_defaults_original_$(date +%Y-%m-%d).json
  bash ~/.macos

  # cloud provider credentials
  [[ -f ~/.aws_auth ]] || (umask 177 ; touch ~/.aws_auth)
  # TODO: automatically create ~/.aws_auth by pulling secrets from lpass cli
  [[ -f ~/.gce_auth ]] || (umask 177 ; touch ~/.gce_auth)
  # TODO: automatically create ~/.gce_auth by pulling secrets from lpass cli

  [[ -d ~/build ]] || mkdir ~/build

fi

# setup git
if ! hash git 2>/dev/null ; then
  if ${IS_OSX} ; then
    if ! hash brew 2>/dev/null ; then
      echo "Installing brew"
      /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    fi
    git config --global user.name "${CUSTOM_FULL_NAME}"
    git config --global user.email "${CUSTOM_WORK_EMAIL}"
  elif ${is_debian} ; then
    sudo apt-get udpate && sudo apt-get install git -y
    git config --global user.name "${CUSTOM_FULL_NAME}"
    git config --global user.email "${CUSTOM_WORK_EMAIL}"
  elif ${is_rhel} ; then
    sudo yum install git -y
    git config --global user.name "${CUSTOM_WORK_EMAIL/\.*/}"
    git config --global user.email "github@${CUSTOM_HOME_DOMAIN}.net"
  fi
fi

# install software
if ${IS_LINUX} && ! hash pip 2>/dev/null ; then
  if ${is_debian} ; then
    echo "Configuring Debian. This will take a few minutes."
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    sudo apt-get install -y python-pip python-dev python3 tmux ack-grep

    # if you must install docker on a full blown OS
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
    sudo apt-get update
    sudo apt-get install -y docker-ce
    sudo systemctl enable docker
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
    sudo yum install python-pip python-dev python3 tmux ack -y
  fi
  # install the rest via pip
    # sudo easy_install pip
  # vagrant, packer, python2+3, ansible, ruby, virtualbox?, gems, docker-ce, fleetctl, java, dos2unix
  # aws and gce/gke CLIs will be installed via ~/.bashrc.d/*
  sudo pip install PyYAML jinja2 paramiko ansible packer vagrant markupsafe
fi

# platform agnostic stuff
# kubernetes stuff
if [[ ! -f !/.kube/config ]] ; then
  echo "pull down file from lastpass to ~/.kube/config"
fi

# setup homeshick (after git)
# /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
if ! [[ -d $HOME/.homesick/repos/homeshick ]] ; then
  git clone git://github.com/andsens/homeshick.git $HOME/.homesick/repos/homeshick
  source "$HOME/.homesick/repos/homeshick/homeshick.sh"
  homeshick clone kr3cj/dotfiles
else
  source $HOME/.homesick/repos/homeshick/homeshick.sh
  # homeshick pull
  homeshick --quiet refresh
fi

# setup lastpass
if ! hash lpass 2>/dev/null ; then
  if ${IS_OSX} ; then
    brew install lastpass-cli --with-pinentry
  elif ${is_debian} ; then
    sudo apt-get install lpass -y
  elif ${is_rhel} ; then
    sudo yum install lpass -y
  fi
fi

# create empty ssh keys
for key in id_rsa id_rsa_hudson id_rsa_coreos ; do
  [[ -f ~/.ssh/${key} ]] || (umask 177 ; touch ~/.ssh/${key})
  # cp -av ~build/ei/jenkins-home/.ssh/id_rsa ~/.ssh/id_rsa_hudson
  # lastpass-cli -f "coreos root key/Private Key/" ~/.ssh/id_rsa_coreos
done

# upgrade software Fridays at 10am
if ! $(crontab -l | grep -q workstation_update) ; then
  (crontab -l 2>/dev/null; echo "0 10 * * 5 ~/.workstation_update.sh") | crontab -
fi
