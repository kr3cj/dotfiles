#!/bin/bash
# the purpose of this script is to install my homeshick dotfiles from github

# first, make sure git is installed
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
    echo "Unknown distro."
    exit 0
  fi
fi

# second, set up homeshick repos
if [[ ! -d $HOME/.homesick/repos/homeshick ]]; then
  git clone https://github.com/andsens/homeshick.git $HOME/.homesick/repos/homeshick
else
  ( cd $HOME/.homesick/repos/homeshick; git pull )
fi
hash homeshick 2> /dev/null || source $HOME/.homesick/repos/homeshick/homeshick.sh

# TODO: not sure if dotfiles_private will work with the conditionals
repos="kr3cj/dotfiles \
 kr3cj/liquidprompt \
 https://kr3cj@bitbucket.org/kr3cj/dotfiles_private.git \
 sudermanjr/tmux-kube"
for repo in ${repos}; do
  if homeshick list | grep -q ${repo}; then
    if [[ ${TRAVIS_CI_RUN} == true ]] && [[ ${repo} =~ "dotfiles_private" ]]; then
      continue;
    fi
    homeshick --batch pull ${repo/*\//}
  else
    # TODO: switch between git@ or https:// syntax accordingly
    homeshick --batch clone ${repo}
  fi
done
homeshick --force link

source ~/.bash_profile
