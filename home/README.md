`~/.bash_profile` manages many things. Here is a what a fresh run might produce:

```
net.link.ether.inet.arp_unicast_lim: 3 -> 1
Initialising new SSH agent...
Enter passphrase for /Users/${CUSTOM_WORK_EMAIL/\@*/}/.ssh/id_rsa:
Identity added: /Users/${CUSTOM_WORK_EMAIL/\@*/}/.ssh/id_rsa (/Users/${CUSTOM_WORK_EMAIL/\@*/}/.ssh/id_rsa)
Enter passphrase for /Users/${CUSTOM_WORK_EMAIL/\@*/}/.ssh/id_rsa:
Bad passphrase, try again for /Users/${CUSTOM_WORK_EMAIL/\@*/}/.ssh/id_rsa:
Identity added: /Users/${CUSTOM_WORK_EMAIL/\@*/}/.ssh/id_rsa (/Users/${CUSTOM_WORK_EMAIL/\@*/}/.ssh/id_rsa)
Identity added: /Users/${CUSTOM_WORK_EMAIL/\@*/}/.ssh/id_rsa_coreos (/Users/${CUSTOM_WORK_EMAIL/\@*/}/.ssh/id_rsa_coreos)
Identity added: /Users/${CUSTOM_WORK_EMAIL/\@*/}/.ssh/id_rsa_hudson (/Users/${CUSTOM_WORK_EMAIL/\@*/}/.ssh/id_rsa_hudson)
Not logged in.
Success: Logged in as lastpass@${CUSTOM_HOME_DOMAIN}.
Establishing ssh tunnel to forinf2.${CUSTOM_WORK_DOMAINS[0]}
Establishing ssh tunnel to laxinf2.${CUSTOM_WORK_DOMAINS[0]}
Establishing ssh tunnel to "home.${CUSTOM_HOME_DOMAIN}" for SOCKS5 Proxy...
${CUSTOM_WORK_EMAIL/\.*/}@home.${CUSTOM_HOME_DOMAIN}'s password:
      refresh The castles dotfiles,homeshick are outdated.
        pull? [yN] y
      symlink .atom/config.cson
      symlink .bash_profile
      symlink .bash_profile_osx
      symlink .bashrc
      symlink .bashrc.d/alias
      symlink .bashrc.d/aws
      symlink .bashrc.d/docker
      symlink .bashrc.d/gce
      symlink .bashrc.d/git
      symlink .bashrc.d/go
      symlink .bashrc.d/history
      symlink .bashrc.d/homeshick
      symlink .bashrc.d/python3
      symlink .bootstrap.sh
      symlink .gitignore
      symlink .inputrc
      symlink .macos
      symlink .ssh/config
      symlink .ssh/id_rsa.pub
      symlink .ssh/ssh-agent-setup
      symlink .vim/puppet.vim
      symlink .vimrc
      symlink .workstation_setup.sh
      symlink .workstation_update.sh
```

`~/.workstation_update.sh` attempts to update all possibly client binaries and artifacts. Here is what a run might look like:

```
${CUSTOM_WORK_EMAIL/\@*/}@MC02RR283FVH6 ~ () $ ~/.workstation_update.sh

Updating OSX system...
Software Update Tool

Finding available software
No updates are available.

Updating OSX App Store apps...
Upgrading 3 outdated applications:
Xcode (9.0), Keynote (7.3), Microsoft Remote Desktop 8.0 (8.0.43)
#############################------------------------------- 49.0% Downloading
...
==> Installed Xcode
==> Downloading Microsoft Remote Desktop 8.0
==> Installed Microsoft Remote Desktop 8.0

Updating brew...
Updating Homebrew...
==> Downloading https://homebrew.bintray.com/bottles-portable/portable-ruby-2.3.3.leopard_64.bottle.1.tar.gz
######################################################################## 100.0%
==> Pouring portable-ruby-2.3.3.leopard_64.bottle.1.tar.gz
==> Auto-updated Homebrew!
Updated 2 taps (caskroom/cask, homebrew/core).
==> New Formulae
abyss                   bwfmetaedit             fn                      libbitcoin-node         xmrig
beast                   clac                    gdcm                    libbitcoin-server       ykman
bettercap               configen                landscaper              liquid-dsp              zim
bowtie2                 dvanalyzer              libbitcoin-blockchain   ssh-vault
...

Skipping reinstall of brew cask "virtualbox" (known issues with non-root installs at time of coding).

Updating atom editor plugins.
Package Updates Available (0)
└── (empty)

Updating gems...
Updating rubygems-update

Skipping reinstall of brew cask "virtualbox" (known issues with non-root installs at time of coding).

Updating atom editor plugins.
Package Updates Available (0)
└── (empty)

Updating gems...
Updating rubygems-update

Skipping reinstall of brew cask "virtualbox" (known issues with non-root installs at time of coding).

Updating atom editor plugins.
Package Updates Available (0)
└── (empty)

Updating gems...
Updating rubygems-update

Skipping reinstall of brew cask "virtualbox" (known issues with non-root installs at time of coding).

Updating atom editor plugins.
Package Updates Available (0)
└── (empty)

Updating gems...
Updating rubygems-update

Skipping reinstall of brew cask "virtualbox" (known issues with non-root installs at time of coding).

Updating atom editor plugins.
Package Updates Available (0)
└── (empty)

Updating gems...
Updating rubygems-update

Skipping reinstall of brew cask "virtualbox" (known issues with non-root installs at time of coding).

Updating atom editor plugins.
Package Updates Available (0)
└── (empty)

Updating gems...
Updating rubygems-update

Skipping reinstall of brew cask "virtualbox" (known issues with non-root installs at time of coding).

Updating atom editor plugins.
Package Updates Available (0)
└── (empty)

Updating gems...
Updating rubygems-update

Skipping reinstall of brew cask "virtualbox" (known issues with non-root installs at time of coding).

Updating atom editor plugins.
Package Updates Available (0)
└── (empty)

Updating gems...
Updating rubygems-update

Skipping reinstall of brew cask "virtualbox" (known issues with non-root installs at time of coding).

Updating atom editor plugins.
Package Updates Available (0)
└── (empty)

Updating gems...
Updating rubygems-update
...

Updating installed gems
Updating bundler

Updating pip...
...

Updating gcloud...
...

```