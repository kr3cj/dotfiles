#!/usr/bin/env bash

# this script checks for and creates a socks proxy connection over ssh
# it should be called by macos launchd or crontab
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

function _check_socks_proxy {
  local host1=${1}
  local port1=${2}
  local host1_ip="$(/usr/bin/dig @1.1.1.1 +short ${host1} | $(brew --prefix grep)/libexec/gnubin/grep '^[.0-9]*$' | tail -n1)"
  local response
  response="$($(brew --prefix curl)/bin/curl --connect-timeout 5 --silent --socks5 localhost:${port1} https://ifconfig.me | $(brew --prefix grep)/libexec/gnubin/grep '^[.0-9]*$' | tail -n1)"
  if [[ "${response}" != "${host1_ip}" ]] ; then
    return 1
  else
    return 0
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

  if ! _check_socks_proxy ${host1} ${port1}; then
    echo "socks proxy not connected/working; first kill any old sessions at $(date)"
    /usr/bin/pgrep -f "/usr/bin/ssh ${ssh_proxy_options} ${port1} ${host1}" && \
    /usr/bin/pkill -f "/usr/bin/ssh ${ssh_proxy_options} ${port1} ${host1}"

    echo -e "\nEstablishing ssh tunnel with ${host1}:${port1} (/usr/bin/ssh ${ssh_proxy_options} ${port1} \"${host1}\") at $(date)"
    if ! port ${host1}:22 &> /dev/null; then
      echo "ERROR: Skipping ${funcstack[1]}; unable to connect to \"${host1}:22\" at $(date)."
      return 1
    else
      eval "/usr/bin/ssh ${ssh_proxy_options} ${port1} ${host1}"
    fi
  fi
}

source ~/.base_homeshick_vars
source ~/.zshrc.d/01-alias
_create_socks_proxy "home.${CUSTOM_HOME_DOMAIN}" "2000"
