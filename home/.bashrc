# Only set some things when running interactively

if [[ -n "${PS1}" ]]; then
  # check the window size after each command and, if necessary,
  # update the values of LINES and COLUMNS.
  shopt -s checkwinsize

  # set variable identifying the chroot you work in (used in the prompt below)
  if [ -z "${debian_chroot}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
  fi

  # STTY doesn't like being sourced
  # control characters
  stty -echoctl
  # flow control
  stty -ixon
fi

# impatiently detect healthy internet connectivity
export HEALTHY_INTERNET=false
if hash curl 2>/dev/null && $(curl github.com --connect-timeout 1 &> /dev/null); then
  HEALTHY_INTERNET=true
else
  echo "Skipping network related profile tasks as there's no healthy internet connectivity."
fi

export TRAVIS_CI_RUN="${TRAVIS_CI_RUN:-false}"
export LPASS_AGENT_TIMEOUT=172800
export LPASS_DISABLE_PINENTRY=0
# export LPASS_ASKPASS

if [[ "${HEALTHY_INTERNET}" == "true" && "${IS_OSX}" == "true" ]]; then
  # TODO: lpass login rquires "stdin must be a tty"
  # else it returns "Error: Failed to enter correct password."
  # So it cannot be located inside ~/.bashrc.d/
  lpass status > /dev/null || DISPLAY=${DISPLAY:-:0} lpass login --trust lastpass@${CUSTOM_HOME_DOMAIN}
fi

hash git 2>/dev/null || bash ~/.workstation_setup.sh

if [[ -d ${HOME}/.bashrc.d ]]; then
  for dotd in $(find ${HOME}/.bashrc.d -follow -type f -not -name '*.disabled' | sort); do
    # echo "Sourcing ${dotd}..."
    source "${dotd}"
  done
  unset dotd
fi
