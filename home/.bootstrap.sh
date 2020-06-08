#!/usr/bin/env bash
# the purpose of this script is to install my homeshick dotfiles from github

echo "Need sudo password to setup passwdless sudo"
if ! sudo grep -q $(whoami) /etc/sudoers && [[ ${TRAVIS_CI_RUN} != true ]]; then
  sudo bash -c "echo \"$(whoami) ALL=(ALL) NOPASSWD: ALL\" >> /etc/sudoers"
fi

# install git
if [[ $(uname) == "Darwin" ]] ; then
  sudo /usr/sbin/softwareupdate --install --all --restart
  # use app store instead if xcode isn't updated by softwareupdate
  # https://apple.stackexchange.com/questions/341706/cant-update-developer-tools-on-mojavehttps://apple.stackexchange.com/questions/341706/cant-update-developer-tools-on-mojave
  xcode-select --install # TODO: make non-interactive
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)" # TODO: make non-interactive
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

# set up homeshick repos
if [[ ! -d ${HOME}/.homesick/repos/homeshick ]]; then
  git clone https://github.com/andsens/homeshick.git ${HOME}/.homesick/repos/homeshick
else
  ( cd ${HOME}/.homesick/repos/homeshick; git pull )
fi
hash homeshick 2> /dev/null || source ${HOME}/.homesick/repos/homeshick/homeshick.sh

# sudermanjr/tmux-kube
for public_repo in kr3cj/dotfiles kr3cj/liquidprompt rfocosi/otp-cli; do
  if homeshick list | grep -q ${public_repo}; then
    # must trim long git URIs to just repo name
    homeshick --batch pull $(echo ${public_repo/*\//} | sed -e "s/\.git$//")
  else
    homeshick --batch clone ${public_repo}
  fi
done
homeshick --force link

if [[ ${TRAVIS_CI_RUN} != true ]]; then
  # this prevents workstation update from running before workstation setup in travis builds
  grep -q local /etc/shells || bash ~/.workstation_setup.sh
fi
[[ -f ~/.bash_profile ]] && source ~/.bash_profile
