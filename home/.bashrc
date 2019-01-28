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

export TRAVIS_CI_RUN="${TRAVIS_CI_RUN:-false}"

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
export LPASS_AGENT_TIMEOUT=172800
export LPASS_DISABLE_PINENTRY=0
# https://github.com/lastpass/lastpass-cli/blob/master/log.h
# export LPASS_LOG_LEVEL=7
# export LPASS_ASKPASS

if [[ "${HEALTHY_INTERNET}" == "true" ]]; then
  # TODO: lpass login rquires "stdin must be a tty"
  # else it returns "Error: Failed to enter correct password."
  # So it cannot be located inside ~/.bashrc.d/
  if ! ${timeout_path} 1 lpass status > /dev/null; then
    # echo "Will try to log into lastpass..."
    DISPLAY=${DISPLAY:-0}
    if [[ "${IS_OSX}" == "true" ]]; then
      $(brew --prefix coreutils)/libexec/gnubin/timeout 2 \
      "lpass login --trust lastpass@${CUSTOM_HOME_DOMAIN}"
      # || echo "Timeout running lpass login"
    elif [[ "${IS_LINUX}" == "true" ]]; then
      [[ -d ~/.local/share/lpass ]] || (umask 077; mkdir -pv ~/.local/share/lpass)
      timeout 2 "lpass login --trust lastpass@${CUSTOM_HOME_DOMAIN}"
      # || echo "Timeout running lpass login"
    fi
  fi
  # if lastpass extension becomes unresponse, delete .suid and .uid from and restart browser
  # srm -v ~/Library/Containers/com.lastpass.LastPass/Data/Library/Application Support/LastPass/{}
fi

if [[ ${TRAVIS_CI_RUN} != true ]]; then
  # this prevents workstation update from running before workstation setup in travis builds
  hash git 2>/dev/null || bash ~/.workstation_setup.sh
fi

if [[ -d ${HOME}/.bashrc.d ]]; then
  for dotd in $(find ${HOME}/.bashrc.d -follow -type f -not -name '*.disabled' | sort); do
    # echo "Sourcing ${dotd}..."
    source "${dotd}"
  done
  unset dotd
fi
