# https://superuser.com/questions/544989/does-tmux-sort-the-path-variable
if [[ -f /etc/profile ]]; then
    PATH=""
    source /etc/profile
fi

[[ -f ~/.bashrc ]] && source ~/.bashrc
