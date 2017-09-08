echo "Initial \$PATH: \"${PATH}\""
[[ -f ~/.base_homeshick_vars ]] && source ~/.base_homeshick_vars
export IS_OSX="false"
export IS_LINUX="false"
case "$(uname)" in
  Darwin)
    IS_OSX="true" && source ~/.bash_profile_osx ;;
  Linux)
    ## source ~/.bash_profile_linux
    IS_LINUX="true" ;;
  *)
    echo "Unable to determine Linux or OSX" ;;
esac

[[ -f ~/.bashrc ]] && source ~/.bashrc

# add admin paths, replace osx utilities with GNU core utilities (should already include /usr/sbin/ and /sbin )
for newpath in \
  /usr/local/sbin \
  /usr/local/opt/coreutils/libexec/gnuman \
  /usr/local/opt/coreutils/libexec/gnubin \
  ; do
  pathadd ${newpath}
done

if ! hash git 2>/dev/null ; then
  echo "System looks new; setting up softare"
  bash ~/.workstation_setup.sh
fi
