if [[ -d ${HOME}/.bashrc.d ]]; then
  while read dotd; do
#    echo "${dotd}..."
    source "${dotd}"
  done < <(find ${HOME}/.bashrc.d -follow -type f -not -name '*.disabled')
  unset dotd
fi
homeshick --quiet refresh
homeshick link dotfiles

cd ~/build/users/billing
