[[ -f ~/.base_homeshick_vars ]] && source ~/.base_homeshick_vars
[[ -f ~/.bashrc ]] && source ~/.bashrc

# add admin paths
for PATH1 in /sbin /usr/sbin /usr/local/sbin ; do
  ( [[ -d ${PATH1} ]] && [[ ! "${PATH}" =~ (^|:)"${PATH1}"(:|$) ]] ) && export PATH="${PATH1}:$PATH"
done

if [[ $(uname) == "Darwin" ]] ; then
  export IS_OSX="true"
  source ~/.bash_profile_osx
fi
if [[ $(uname) == "Linux" ]] ; then
  export IS_LINUX="true"
  source ~/.bash_profile_linux
fi

if ! hash git 2>/dev/null ; then
  echo "System looks new; setting up softare"
  bash ~/.workstation_setup.sh
fi
