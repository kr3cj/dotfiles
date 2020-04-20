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
  # flow control
  stty -ixon
fi

# control characters
stty -echoctl

export TRAVIS_CI_RUN="${TRAVIS_CI_RUN:-false}"
[[ -f ~/.base_homeshick_vars ]] && source ~/.base_homeshick_vars

# impatiently detect healthy internet connectivity; prereq for LPASS stuff
export HEALTHY_INTERNET=false
export timeout_path
if [[ -e /usr/local/opt/coreutils/libexec/gnubin/timeout ]]; then
  timeout_path=/usr/local/opt/coreutils/libexec/gnubin/timeout
elif [[ -e /usr/bin/timeout ]]; then
  timeout_path=/usr/bin/timeout
# else
  # dont echo from within bashrc: https://bugzilla.redhat.com/show_bug.cgi?id=20527
  # echo "Unable to find timeout command. Skipping network related profile tasks."
fi

if hash curl 2>/dev/null && ${timeout_path} 1 curl github.com; then
  HEALTHY_INTERNET=true
fi
# lastpass stuff cannot be inside bashrc.d file due to tty req'ts
export LPASS_AGENT_TIMEOUT=86400
export LPASS_DISABLE_PINENTRY=0
# https://github.com/lastpass/lastpass-cli/blob/master/log.h
# export LPASS_LOG_LEVEL=7
# export LPASS_ASKPASS

if [[ "${HEALTHY_INTERNET}" == "true" ]] ; then
  if ! ${timeout_path} 1 lpass status > /dev/null; then
    DISPLAY=${DISPLAY:-0}
    if [[ "${IS_LINUX}" == "true" ]]; then
      [[ -d ~/.local/share/lpass ]] || (umask 077; mkdir -pv ~/.local/share/lpass)
    fi
    # using timeout stunts the TUI: ${timeout_path} 10
    lpass login --trust lastpass@${CUSTOM_HOME_DOMAIN}
  fi
  # if lastpass extension becomes unresponse, delete .suid and .uid from and restart browser
  # srm -v ~/Library/Containers/com.lastpass.LastPass/Data/Library/Application Support/LastPass/{}
fi

if [[ -d ${HOME}/.bashrc.d ]]; then
  for dotd in $(find ${HOME}/.bashrc.d -follow -type f -not -name '*.disabled' | sort); do
    if [[ ${VERBOSE} -gt 0 ]]; then
      echo "Sourcing ${dotd}..."
      time -p source "${dotd}"
    else
      source "${dotd}"
    fi
  done
  unset dotd
fi
