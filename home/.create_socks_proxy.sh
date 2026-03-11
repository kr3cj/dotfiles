#!/usr/bin/env bash

# this script checks for and creates a socks proxy connection over ssh
# it should be called by macos launchd or crontab
 # launchctl load -w ~/Library/LaunchAgents/create_socks_proxy.plist
 # plutil ~/Library/LaunchAgents/create_socks_proxy.plist
# it should have prerequisite configs in ~/.ssh/config and ssh-agent

# test that we are on macos
if ! [[ $(uname) == "Darwin" ]]; then
  exit 0
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
export PATH="${BASE_PATH}/bin:${BASE_PATH}/bin/mise:${LOG_NAME}/.local/share/mise/shims:${PATH}"

# test for healthy internet connection
export timeout_path
if [[ -e /usr/local/bin/timeout ]]; then
  timeout_path=/usr/local/bin/timeout
elif [[ -e /opt/homebrew/bin/timeout ]]; then
  timeout_path=/opt/homebrew/bin/timeout
elif [[ -e /usr/bin/timeout ]]; then
  timeout_path=/usr/bin/timeout
fi
export curl_path
if [[ -x "${BASE_PATH}/opt/curl/bin/curl" ]]; then
  curl_path="${BASE_PATH}/opt/curl/bin/curl"
elif [[ -x "${BASE_PATH}/bin/curl" ]]; then
  curl_path="${BASE_PATH}/bin/curl"
else
  curl_path="/usr/bin/curl"
fi
if ! /usr/bin/hash "${curl_path}" 2>/dev/null; then
  exit 0
fi
if [[ -n "${timeout_path}" ]] && ! "${timeout_path}" 3 "${curl_path}" --silent --head --fail https://github.com > /dev/null 2>&1; then
  exit 0
fi

function _socks_proxy_is_alive {
  local proxy_port1=${2}
  # Check if an ssh process is listening on the SOCKS port locally
  if /usr/sbin/lsof -nPiTCP:${proxy_port1} -sTCP:LISTEN -c ssh > /dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}
function _create_socks_proxy {
  local host1=${1}
  local proxy_port1=${2}
  local ssh_port1=${3:-"22"}
  local ssh_proxy_options="-o ServerAliveInterval=10 -o ServerAliveCountMax=20 -f -N -D "
  # local ssh_proxy_options="-f -N -D "
  [[ ${VERBOSE} -ge 1 ]] && ssh_proxy_options="-vvv ${ssh_proxy_options}"
  local ssh_proxy_response_file="/var/tmp/ssh_proxy_response.txt"
  # clear contents of response file
  :> ${ssh_proxy_response_file}

  if ! _socks_proxy_is_alive ${host1} ${proxy_port1}; then
    echo "$(date -Iseconds) WARN: socks proxy not connected/working; first kill any old sessions"
    local existing_ssh_pid
    existing_ssh_pid=$(/usr/sbin/lsof -tiTCP:${proxy_port1} -sTCP:LISTEN -c ssh 2>/dev/null | /usr/bin/head -n1)
    if [[ -n "${existing_ssh_pid}" ]]; then
      echo "$(date -Iseconds) INFO: killing stale ssh process ${existing_ssh_pid}"
      /bin/kill "${existing_ssh_pid}"
    fi

    # Connect without a raw TCP pre-check (which causes invalid protocol errors on the target)
    /usr/bin/ssh ${ssh_proxy_options} "${proxy_port1}" -p "${ssh_port1}" "${host1}"
    [[ ${?} -eq 0 ]] && echo "$(date -Iseconds) INFO: established ssh tunnel with ${host1}:${proxy_port1}"
  else
    [[ ${VERBOSE} -ge 1 ]] && echo "$(date -Iseconds) INFO: socks proxy already connected/working; skipping"
  fi
}

source ~/.base_homeshick_vars
source ~/.zshrc.d/01-alias

# grab all ip addresses
ip_address=$(/sbin/ifconfig 2> /dev/null | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | tr "\n" ' ')
case "${ip_address}" in
  *${CUSTOM_HOME_SUBNET%.*\.}.2.*)
    [[ ${VERBOSE} -ge 1 ]] && echo "at home"
    SOCKS_HOST="${CUSTOM_HOME_SOCKS_LOCAL}"
    SSH_PORT="22"
    ;;
  *${CUSTOM_WORK_SUBNET}*)
    [[ ${VERBOSE} -ge 1 ]] && echo "at work"
    SOCKS_HOST="home.${CUSTOM_HOME_DOMAIN}"
    SSH_PORT="222"
    ;;
  *)
    [[ ${VERBOSE} -ge 1 ]] && echo "elsewhere"
    SOCKS_HOST="home.${CUSTOM_HOME_DOMAIN}"
    SSH_PORT="222"
    ;;
esac
[[ ${VERBOSE} -ge 1 ]] && echo "About to run: _socks_proxy_is_alive ${SOCKS_HOST} 2000"
_create_socks_proxy "${SOCKS_HOST}" "2000" "${SSH_PORT}"
