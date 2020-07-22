if [[ "$(uname)" == "Darwin" ]] && [[ -f /etc/profile ]]; then
  # https://superuser.com/questions/544989/does-tmux-sort-the-path-variable
  # https://wiki.archlinux.org/index.php/tmux#Start_a_non-login_shell
  PATH=""
  . /etc/profile
fi

[[ -f ~/.bashrc ]] && . ~/.bashrc

export PATH="$HOME/.asdf/installs/poetry/1.0.10/bin:$PATH"
