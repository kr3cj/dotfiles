# Only set some things when running interactively

if [[ -n "$PS1" ]]; then
  # check the window size after each command and, if necessary,
  # update the values of LINES and COLUMNS.
  shopt -s checkwinsize

  # set variable identifying the chroot you work in (used in the prompt below)
  if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
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

export LPASS_AGENT_TIMEOUT=172800
export LPASS_DISABLE_PINENTRY=0
# export LPASS_ASKPASS

if [[ "${HEALTHY_INTERNET}" == "true" && "${IS_OSX}" == "true" ]]; then
  # TODO: in order for the login command to work, "stdin must be a tty"
  # otherwise it returns "Error: Failed to enter correct password."
  # So it cannot be located inside ~/.bashrc.d/
  lpass status > /dev/null || lpass login --trust lastpass@${CUSTOM_HOME_DOMAIN}
fi

if ! hash git 2>/dev/null ; then
  bash ~/.workstation_setup.sh
fi

if [[ -d ${HOME}/.bashrc.d ]]; then
  while read dotd; do
    # echo "Sourcing ${dotd}..."
    source "${dotd}"
  done < <(find ${HOME}/.bashrc.d -follow -type f -not -name '*.disabled' | sort)
  unset dotd
fi
