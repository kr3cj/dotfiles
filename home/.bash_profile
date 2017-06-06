#set -x
[[ -f ~/.base_homeshick_vars ]] && source ~/.base_homeshick_vars
[[ -f ~/.bashrc ]] && source ~/.bashrc

# add admin paths
for PATH1 in /sbin /usr/sbin /usr/local/sbin ; do
  ( [[ -d ${PATH1} ]] && [[ ! "${PATH}" =~ (^|:)"${PATH1}"(:|$) ]] ) && export PATH="${PATH1}:$PATH"
done

# Workaround for OSX incompatibility with commercial routers
[[ $(sysctl -n net.link.ether.inet.arp_unicast_lim) -ne 1 ]] && \
  sudo sysctl -w net.link.ether.inet.arp_unicast_lim=1

# impatiently detect healthy internet connectivity
have_network="true"
GATEWAY=$(netstat -nr | grep default | head -n1 | awk '{print $2}')
if ! $(curl github.com --connect-timeout 1 &> /dev/null); then
  echo "Detected slow speed for internet connectivity."
  have_network="false"
fi
if [[ "${have_network}" == "true" ]] ; then
  # set up network related profile

  # get network awaremenss
  ip_address=""
  is_mac="false"
  is_debian="false"
  is_rhel="false"
  at_work="false"
  at_home="false"

  if [[ $(uname) == "Darwin" ]] ; then
    is_mac="true"
    ip_address=$(/sbin/ifconfig en0 | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}')

    # ssh agent stuff
    . $HOME/.ssh/ssh-agent-setup
    [[ -z "$(launchctl getenv SSH_AUTH_SOCK)" ]] && eval $(ssh-agent -s)
    [[ $(ssh-add -l | wc -l) -lt 3 ]] && ssh-add -k ~/.ssh/{id_rsa,id_rsa_coreos,id_rsa_hudson}

    # lastpass
    export LPASS_AGENT_TIMEOUT=172800
    if ! lpass status 2>/dev/null ; then lpass login --trust lastpass@${CUSTOM_HOME_DOMAIN} ; fi
    lpw

  elif [[ $(uname) == "Linux" ]] ; then
    # only proceed for Linux workstations
    if [[ $(runlevel | cut -d ' ' -f2) -le 3 ]] ; then
      echo "Quitting workstation setup on what appears to be a server"
      exit 0
    fi
    ip_address=$(ip addr show | grep 'inet ' | grep -v 127 | head -n1 | awk '{print $2}' | cut -d/ -f1)
    if [[ -f /etc/redhat-release ]] ; then
      is_rhel="true"
    elif [[ -f /etc/os-version ]] ; then
      is_debian="true"
    fi
  else
    echo "Unable to determine unix distro."
  fi

  # figure out location
  ( [[ ${ip_address} =~ "${CUSTOM_WORK_SUBNET}.49." ]] || [[ ${ip_address} =~ "${CUSTOM_WORK_SUBNET}.200." ]] \
    || [[ ${ip_address} =~ "${CUSTOM_WORK_SUBNET}.67." ]] ) && at_work="true"
  [[ ${ip_address} =~ "${CUSTOM_HOME_SUBNET}" ]] && at_home="true"

  if ${at_home} ; then
    mount -t nfs -o vers=4,rw,soft,intr,bg,rsize=32768,wsize=32768,dsize=32768 \
      ${CUSTOM_NAS_HOST}:/share ~/Documents/share1
  fi
  if ${at_work} ; then
    # set up SSH tunnel if not already set up
    lsof -n -i4TCP:2000 | grep LISTEN &>/dev/null
    if [[ ${?} -eq 1 ]] ; then
      echo "Establishing SSH Tunnel for SOCKS5 Proxy"
      ssh -f -N -o TCPKeepAlive=yes -o StrictHostKeyChecking=no -D 2000 ${CUSTOM_WORK_EMAIL/\.*/}@home.${CUSTOM_HOME_DOMAIN} >/dev/null
    fi
  fi
else
  echo "Skipping network related profile tasks as there's no healthy internet connectivity."
fi

if ! hash git 2>/dev/null ; then
  echo "System looks new; setting up softare"
  bash ~/.workstation_setup.sh
fi
#set +x
