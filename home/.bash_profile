# temporary troubleshooting
[[ ${HISTSIZE} -lt 1000000 ]] && echo -e "\nSomething has overridden \${HISTSIZE} to ${HISTSIZE}!!!\n"

[[ -f ~/.base_homeshick_vars ]] && source ~/.base_homeshick_vars
export IS_OSX="false"
export IS_LINUX="false"
case "$(uname)" in
  Darwin)
    IS_OSX="true" ;;
  Linux)
    IS_LINUX="true" ;;
  *)
    echo "Unable to determine Linux or OSX" ;;
esac

# impatiently detect healthy internet connectivity
export HEALTHY_INTERNET=false
if hash curl 2>/dev/null && $(curl github.com --connect-timeout 1 &> /dev/null); then
  HEALTHY_INTERNET=true
else
  echo "Skipping network related profile tasks as there's no healthy internet connectivity."
fi

[[ -f ~/.bashrc ]] && source ~/.bashrc

# add admin paths, replace osx utilities with GNU core utilities (should already include /usr/sbin/ and /sbin )
# /usr/local/Cellar/findutils/4.6.0/bin \
# /usr/local/opt/gnu-sed/libexec/gnubin \
# /usr/local/opt/gnu-tar/libexec/gnubin \
for newpath in \
  /usr/sbin \
  /usr/local/sbin \
  /usr/local/opt/coreutils/libexec/gnubin \
  ; do
  pathadd ${newpath}
done

if ! hash git 2>/dev/null ; then
  bash ~/.workstation_setup.sh
fi
