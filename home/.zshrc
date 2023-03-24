export GHA_CI_RUN="${GHA_CI_RUN:-false}"
[[ -f ~/.base_homeshick_vars ]] && source ~/.base_homeshick_vars

export MYSHELL=$(printf "%s\n" $0)

# impatiently detect healthy internet connectivity; prereq for passwd mgr stuff
export HEALTHY_INTERNET=false
export timeout_path
if [[ -e /usr/local/bin/timeout ]]; then
  timeout_path=/usr/local/bin/timeout
elif [[ -e /opt/homebrew/bin/timeout ]]; then
  timeout_path=/opt/homebrew/bin/timeout
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

export IS_MACOS="false"
export IS_LINUX="false"
export IS_ARM="false"
case "$(uname)" in
  Darwin)
    export IS_MACOS="true" ;;
  Linux)
    export IS_LINUX="true" ;;
  *)
    echo "Unable to determine linux or macos" ;;
esac
case "$(uname -m)" in
  arm64)
    export IS_ARM="true"
esac

if [[ -d ${HOME}/.zshrc.d ]]; then
  for dotd in $(find ${HOME}/.zshrc.d -follow -type f -not -name '*.disabled' | sort); do
    if [[ ${VERBOSE} -gt 0 ]]; then
      echo "Sourcing ${dotd}..."
      # TODO why doesnt time prefix work
      source ${dotd}
      [[ ${?} -ne 0 ]] && echo "Failed to source ${dotd}!"
    else
      source ${dotd}
    fi
  done
fi
