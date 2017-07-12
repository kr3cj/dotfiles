#!/bin/bash
# the purpose of this script is to house all initial workstation customizations in linux or osx

# get my bearings
ip_address=""
is_debian="false"
is_rhel="false"
at_work="false"

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

# setup git
if ! hash git 2>/dev/null ; then
  if ${IS_OSX} ; then
    if ! hash brew 2>/dev/null ; then
      echo "Installing brew"
      /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    fi
    brew install git
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
if ${IS_OSX} && ! hash mas 2>/dev/null ; then
  echo "Configuring OSX. This will take an hour or so."
  brew tap homebrew/dupes && brew install bash coreutils findutils gnu-tar \
    gnu-sed gawk gnutls gnu-indent gnu-getopt nmap grep mtr ack \
    aria2 mas mtr wget dos2unix \
    ansible awscli docker docker-compose fleetctl go java openshift-cli packer python python3 rbenv ruby ruby-build
  # puppet testing shtuff
  sudo gem install bundler
  # mas is a CLI for AppStore installs/updates
  mas signin ${CUSTOM_WORK_EMAIL}
  mas install 405843582 # Alfred (1.2)
  mas install 497799835 # Xcode
  mas install 595191960 # CopyClip (1.9)
  mas install 715768417 # Microsoft Remote Desktop (8.0.27246)
  # mas install 417375580 # BetterSnapTool (1.7)
  # TODO: f.lux
  sudo rm -rf /Applications/{iMovie.app,GarageBand.app,Pages.app,Numbers.app}
  # install main apps into Applications
  HOMEBREW_CASK_OPTS="--appdir=/Applications"
  brew cask install \
    slack spotify gimp google-photos-backup iterm2 android-file-transfer \
    atom iterm2 vagrant virtualbox jq \
    java keystore-explorer \
    google-cloud-sdk beyond-compare visual-studio-code
  # brew install Caskroom/cask/pycharm-ce
  HOMEBREW_CASK_OPTS=""

  # install atom editor plugins
  apm install terminal-plus minimap language-hcl linter-terraform-syntax \
    autocomplete-bash-builtins linter-checkbashisms markdown-toc terraform-fmt \
    language-groovy
  # language-terraform

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
  pip install pylint virtualenv

  # gce and gke stuff (https://cloud.google.com/sdk/docs/quickstart-mac-os-x)
  go get golang.org/x/tools/cmd/godoc
  gcloud components install kubectl -q
  gcloud init
  gcloud auth list
  gcloud config list
  # must install helm after kubernetes?
  brew install kubernetes-helm
  # install helm plugin for Visual Studio Code
  helm plugin install https://github.com/technosophos/helm-template
  helm init

  # docker for mac
  wget https://download.docker.com/mac/stable/Docker.dmg
  sudo hdiutil attach Docker.img
  sudo installer -package /Volumes/Docker/Docker.pkg -target /Applications
  sudo hdiutil detach "/Volumes/Docker/"

  # prep for home nfs mount
  mkdir ~/Documents/share1
  mkdir ~/Pictures/share1

  ### general osx customizations from https://github.com/mathiasbynens/dotfiles/blob/master/.macos ###
  # first, backup the current defaults
  defaults read > ~/osx_defaults_original_$(date +%Y-%m-%d).json
  bash ~/.macos

  # cloud provider credentials
  [[ -f ~/.aws_auth ]] || (umask 177 ; touch ~/.aws_auth)
  [[ -f ~/.gce_auth ]] || (umask 177 ; touch ~/.gce_auth)

  [[ -d ~/build ]] || mkdir ~/build

fi

if ${IS_LINUX} && ! hash pip 2>/dev/null ; then
  if ${is_debian} ; then
    echo "Configuring Debian. This will take a few minutes."
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    sudo apt-get install -y python-pip python-dev python3 tmux ack-grep
    # packer is a pain on linux
    wget https://releases.hashicorp.com/packer/0.12.3/packer_0.12.3_linux_amd64.zip?_ga=1.256734091.1098021006.1490961258 --output-document=/var/tmp/packer.zip
    unzip /var/tmp/packer.zip -d /usr/local
    sudo ln -s /usr/local/packer /usr/local/bin/packer

    # if you must install docker on a full blown OS
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
    sudo apt-get update
    sudo apt-get install -y docker-ce
    sudo systemctl enable docker
    sudo groupadd docker || true
    sudo usermod -aG docker ${USER}
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
