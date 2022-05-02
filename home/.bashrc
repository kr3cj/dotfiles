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

export GHA_CI_RUN="${GHA_CI_RUN:-false}"
[[ -f ~/.base_homeshick_vars ]] && source ~/.base_homeshick_vars

# impatiently detect healthy internet connectivity; prereq for passwd mgr stuff
export HEALTHY_INTERNET=false
export timeout_path
if [[ -e /usr/local/opt/coreutils/libexec/gnubin/timeout ]]; then
  timeout_path=/usr/local/opt/coreutils/libexec/gnubin/timeout
elif [[ -e /opt/homebrew/bin/coreutils/libexec/gnubin/timeout ]]; then
  timeout_path=/opt/homebrew/opt/coreutils/libexec/gnubin/timeout
elif [[ -e /usr/bin/timeout ]]; then
  timeout_path=/usr/bin/timeout
# else
  # dont echo from within bashrc: https://bugzilla.redhat.com/show_bug.cgi?id=20527
  # echo "Unable to find timeout command. Skipping network related profile tasks."
fi

if hash curl 2>/dev/null && ${timeout_path} 1 curl github.com; then
  HEALTHY_INTERNET=true
else
  echo "No healthy internet detected..."
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

[ -f ~/.fzf.bash ] && source ~/.fzf.bash
