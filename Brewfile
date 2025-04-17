# tap "homebrew/bundle"
# tap "homebrew/cask"
# tap "homebrew/core"
tap "aws/tap"

### base software (gnu core utilities)
brew "coreutils"
brew "binutils"
brew "curl"
brew "diffutils"
brew "ed"
brew "findutils"
brew "gawk"
# brew "gdb" # no bottle for Apple Silicon; gdb needs more actions to work. See `brew info gdb`
brew "gnu-indent"
brew "gnu-sed"
brew "gnu-tar"
brew "gnu-which"
brew "gnupg"
brew "gnupg2"
brew "gnutls"
brew "gpatch"
brew "grep"
brew "guile"
brew "gzip"
brew "ipcalc"
brew "screen"
brew "watch"
brew "wdiff"
brew "wget"

### install newer utilities
brew "bash"
brew "file-formula"
brew "git"
brew "less"
brew "liquidprompt"
brew "rsync"
brew "sops"
brew "tcpdump"
brew "unzip"
brew "vim" # ruby
### not sure what these are for
brew "docker-credential-helper"
brew "m4"

### install extra tools I like
brew "ack"
brew "asdf" # icu4c@76 libxml2 readline
brew "bash-completion"
brew "certigo"
brew "cfssl"
brew "colima"
brew "dive"
brew "docker"
brew "docker-buildx"
brew "docker-compose"
# brew "dos2unix"
brew "ec2-instance-selector"
brew "fzf"
brew "gnu-getopt"
brew "hub"
brew "mas"
brew "mtr"
brew "nmap"
brew "pstree"
brew "shellcheck"
# brew "sslyze" # no bottle for Apple Silicon
brew "step"
brew "tmux"
brew "tree"
brew "reattach-to-user-namespace"

### load testing clients
brew "hey"
brew "siege"
# brew "artillery"
# brew "gauntlet"

### dev stuff
# brew "android-platform-tools"
# brew "ansible"
brew "go"
brew "golang"
brew "jid"
brew "make"
# brew "maven"
# brew "mysql-client"
# brew "node"
# brew "perl518" # tap homebrew/versions
brew "python@3.13"
# brew "rbenv"
# brew "ruby"
# brew "ruby-build"
# brew "svn"
# brew "terraform_landscape"
brew "tfenv"
# brew "travis"

### dont use these anymore
# brew "aria2" # torrent_client(aria2c)
# brew "awless" # no longer maintained (cask "wallix/awless")
# brew "fleetctl"
# brew "go-jira"
# brew "lastpasscli"
# brew "macvim" --with-override-system-vim --custom-system-icons
# brew link --overwrite macvim
# brew linkapps macvim
# brew "nano
# brew "openshift-cli"
# brew "packer"
# brew "vault"
# brew "zsh"

### install these using corporate installer
# slack zoom

### desktop installs
# first, install user casks
cask_args appdir: '~/Applications'

cask "alfred"
cask "firefox"
cask "font-fira-code"
cask "font-fira-code-nerd-font"
cask "gimp"
# cask "goland"
# cask "intellij-idea"
# cask "intellij-idea-ce"
# cask "iterm2"
# cask "keystore-explorer"
# cask "librecad"
# cask "pycharm-ce"
cask "raspberry-pi-imager"

# now install system casks
cask_args appdir: '/Applications'

# cask "android-file-transfer"
cask "brave-browser"
cask "github"
# cask "microsoft-edge"
cask "spotify"
cask "visual-studio-code"
cask "warp"
cask "wireshark"

### App Store installs won't work until authenticated to apple account
mas "CopyClip", id: 595191960
# mas "Keynote", id: 409183694
mas "Magnet", id: 441258766
mas "Microsoft Remote Desktop", id: 1295203466
