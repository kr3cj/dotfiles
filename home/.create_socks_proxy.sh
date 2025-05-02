#!/usr/bin/env bash

# this script checks for and creates a socks proxy connection over ssh
# it should be called by macos launchd or crontab
 # launchctl load -w ~/Library/LaunchAgents/create_socks_proxy.plist
# it should have prerequisite configs in ~/.ssh/config and ssh-agent

# test that we are on macos
if ! [[ $(uname) == "Darwin" ]]; then
  return 0
fi

# use old style path building since we're in bash
export IS_ARM="false"
case "$(/usr/bin/uname -m)" in
  arm64)
    export IS_ARM="true"
esac
BREWBIN_PATH="/usr/local/bin/brew"
[[ "${IS_ARM}" == "true" ]] && BREWBIN_PATH="/opt/homebrew/bin/brew"
BASE_PATH="$(${BREWBIN_PATH} --prefix)"
export PATH="${BASE_PATH}/bin:${BASE_PATH}/opt/asdf/libexec/bin/asdf:${LOG_NAME}/.asdf/shims:${PATH}"

# test for healthy internet connection
export timeout_path
if [[ -e /usr/local/bin/timeout ]]; then
  timeout_path=/usr/local/bin/timeout
elif [[ -e /opt/homebrew/bin/timeout ]]; then
  timeout_path=/opt/homebrew/bin/timeout
elif [[ -e /usr/bin/timeout ]]; then
  timeout_path=/usr/bin/timeout
fi
if ! /usr/bin/hash $(brew --prefix curl)/bin/curl 2>/dev/null && ${timeout_path} 3 $(brew --prefix curl)/bin/curl github.com; then
  return 0
fi

function _socks_proxy_is_alive {
  local host1=${1}
  local port1=${2}
  local sourcesite="https://api.ipify.org?format=yaml" # https://checkip.dyndns.org https://ifconfig.me
  local host1_ip="$(/usr/bin/dig @1.1.1.1 +short ${host1} | $(brew --prefix grep)/libexec/gnubin/grep '^[.0-9]*$' | tail -n1)"
  local response
  response="$($(brew --prefix curl)/bin/curl --connect-timeout 5 --silent --socks5 localhost:${port1} ${sourcesite} \
   | $(brew --prefix grep)/libexec/gnubin/grep '^[.0-9]*$' | tail -n1)"
  if [[ "${response}" == "${host1_ip}" ]] ; then
    return 0
  else
    return 1
  fi
}
function _create_socks_proxy {
  local host1=${1}
  local port1=${2}
  local ssh_proxy_options="-o ServerAliveInterval=10 -o ServerAliveCountMax=20 -f -N -D "
  # local ssh_proxy_options="-f -N -D "
  [[ ${VERBOSE} -ge 1 ]] && ssh_proxy_options="-vvv ${ssh_proxy_options}"
  local ssh_proxy_response_file="/var/tmp/ssh_proxy_response.txt"
  # clear contents of response file
  :> ${ssh_proxy_response_file}

  if ! _socks_proxy_is_alive ${host1} ${port1}; then
    # echo "$(date -Iseconds) INFO: socks proxy already connected/working; skipping"
  # else
    echo "$(date -Iseconds) WARN: socks proxy not connected/working; first kill any old sessions"
    /usr/bin/pgrep -f "/usr/bin/ssh ${ssh_proxy_options}${port1} ${host1}" && \
    /usr/bin/pkill -f "/usr/bin/ssh ${ssh_proxy_options}${port1} ${host1}"

    if ! port ${host1}:22 &> /dev/null; then
      echo "$(date -Iseconds) ERROR: Skipping ${funcstack[1]}; unable to connect to \"${host1}:22\" at $(date)."
      return 1
    else
      # echo "$(date -Iseconds) INFO: attempting ssh tunnel with ${host1}:${port1} \"${host1}\")"
      eval "/usr/bin/ssh ${ssh_proxy_options} ${port1} ${host1}"
      [[ ${?} -eq 0 ]] && echo "$(date -Iseconds) INFO: established ssh tunnel with ${host1}:${port1}"
    fi
  fi
}

source ~/.base_homeshick_vars
source ~/.zshrc.d/01-alias
SOCKS_HOST="home.${CUSTOM_HOME_DOMAIN}"
[[ ${at_home} == "true" ]] && SOCKS_HOST="${CUSTOM_HOME_SOCKS_LOCAL}"
_create_socks_proxy "${SOCKS_HOST}" "2000"
