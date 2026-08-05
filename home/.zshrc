export GHA_CI_RUN="${GHA_CI_RUN:-false}"
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

if hash curl 2>/dev/null && ${timeout_path} 3 curl github.com; then
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

if ${IS_MACOS}; then
  ### Functions for setting and getting environment variables from the OSX keychain ###
  ### Adapted from https://gist.github.com/bmhatfield/f613c10e360b4f27033761bbee4404fd ###
  # Use: keychain-environment-variable SECRET_ENV_VAR
  function keychain-environment-variable () {
    # [[ -z ${1} ]] &&
    security find-generic-password -w -a ${USER} -D "environment variable" -s "${1}"
  }
  # Use: set-keychain-environment-variable SECRET_ENV_VAR
  #   provide: super_secret_key_abc123
  function set-keychain-environment-variable () {
    [ -n "${1}" ] || print "Missing environment variable name"

    # Note: if using bash, use `-p` to indicate a prompt string, rather than the leading `?`
    read -s "?Enter Value for ${1}: " secret

    ( [ -n "${1}" ] && [ -n "$secret" ] ) || return 1
    security add-generic-password -U -a ${USER} -D "environment variable" -s "${1}" -w "${secret}"
  }
fi
[[ -f ~/.base_homeshick_vars ]] && source ~/.base_homeshick_vars

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
