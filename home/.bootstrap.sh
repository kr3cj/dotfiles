#!/bin/bash
# the purpose of this script is to install my homeshick dotfiles from github

# first, create git ignored base dir file
if ! [[ -f ~/.base_homeshick_vars ]] ; then
  echo "Enter your custom full name:"
  read custom_full_name
  echo "Enter your custom ldap name:"
  read custom_ldap_name
  echo "Enter your custom github handle:"
  read custom_github_handle
  echo "Enter your custom home domain name:"
  read custom_home_domain
  echo "Enter your custom home subnet:"
  read custom_nas_host
  echo "Enter your custom work email:"
  read custom_home_subnet
  echo "Enter your custom work subnet:"
  read custom_work_subnet
  echo "Enter your custom work domains (space separated):"
  read custom_work_domains
  echo "Enter your custom nas host (fqdn):"
  read custom_work_email
  echo "Enter your custom work vpn uri for readytalk:"
  read custom_work_vpn_rt
  echo "Enter your custom work vpn uris for PGi (space separated):"
  read custom_work_vpn_pgi
  (umask 077 ; touch ~/.base_homeshick_vars)
  cat << EOF >> ~/.base_homeshick_vars
export CUSTOM_FULL_NAME="${custom_full_name}"
export CUSTOM_LDAP_NAME="${custom_ldap_name}"
export CUSTOM_GITHUB_HANDLE="${custom_github_handle}"
export CUSTOM_HOME_DOMAIN="${custom_home_domain}"
export CUSTOM_NAS_HOST="${custom_nas_host}"
export CUSTOM_HOME_SUBNET="${custom_home_subnet}"
export CUSTOM_WORK_SUBNET="${custom_work_subnet}"
export CUSTOM_WORK_DOMAINS=(${custom_work_domains})
export CUSTOM_WORK_EMAIL="${custom_work_email}"
export CUSTOM_WORK_VPN_RT=(${custom_work_vpn_rt})
export CUSTOM_WORK_VPN_PGI=(${custom_work_vpn_pgi})
EOF
fi
source ~/.base_homeshick_vars

# second, make sure git is installed
if ! hash git 2>/dev/null ; then
  if [[ $(uname) == "Darwin" ]] ; then
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    brew install git
  elif [[ $(uname) == "Linux" ]] ; then
    if [[ -f /etc/redhat-release ]] ; then
      sudo yum install git -y
    elif [[ -f /etc/os-release ]] ; then
      sudo apt-get update && sudo apt-get install git -y
    fi
  else
    echo "Unknown unix distro."
    exit 0
  fi
fi

# third, get and run homeshick
if ! [[ -d ${HOME}/.homesick/repos/homeshick ]] ; then
  mkdir -pv ${HOME}/.homesick/repos/
  git clone git://github.com/andsens/homeshick.git ${HOME}/.homesick/repos/homeshick
  cd ${HOME}/.homesick/repos
  git config user.name "${CUSTOM_WORK_EMAIL/\.*/}"
  git config user.email "github@${CUSTOM_HOME_DOMAIN}"

  source "${HOME}/.homesick/repos/homeshick/homeshick.sh"
  # TODO: pull public rsa key from github/bitbucket/lastpass and remove below conditional
  if [[ -r ~/.ssh/id_rsa.pub ]] ; then
    homeshick --force clone git@github.com:${CUSTOM_GITHUB_HANDLE}/dotfiles
  else
    homeshick --force clone https://github.com:${CUSTOM_GITHUB_HANDLE}/dotfiles
    homeshick cd dotfiles
    git remote set-url origin git@github.com:${CUSTOM_GITHUB_HANDLE}/dotfiles.git
    cd -
  fi

  cd ~
  homeshick link --force
else
  source "${HOME}/.homesick/repos/homeshick/homeshick.sh"
  homeshick pull
  homeshick --quiet --force refresh
  homeshick --quiet --force link dotfiles
fi

# fourth, grab liquidprompt fork
# repo="kr3cj/liquidprompt sudermanjr/tmux-kube"
repo="sudermanjr/tmux-kube"
if homeshick list | grep -q ${repo}; then
  homeshick --batch pull ${repo/*\//}
else
  # TODO: switch between git@ or https:// syntax accordingly
  homeshick --batch clone ${repo}
fi
homeshick --force link

source ~/.bash_profile
