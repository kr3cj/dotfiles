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

if [[ -d ${HOME}/.bashrc.d ]]; then
  while read dotd; do
    # echo "Sourcing ${dotd}..."
    source "${dotd}"
  done < <(find ${HOME}/.bashrc.d -follow -type f -not -name '*.disabled' | sort)
  unset dotd
fi

# remember man page views
# export less="fix"
