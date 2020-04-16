`~/.bash_profile` manages many things. Here is a what a fresh run might produce:

```
Not logged in.
Success: Logged in as lastpass@${CUSTOM_HOME_DOMAIN}.
Must re-authenticate with VAULT (https://vault.${CUSTOM_WORK_DOMAINS[3]}:8200...)
Password (will be hidden):
Enter passphrase for /Users/${LOGNAME}/.ssh/id_rsa:
Identity added: /Users/${LOGNAME}/.ssh/id_rsa (/Users/${LOGNAME}/.ssh/id_rsa)
Lifetime set to 36000 seconds
Identity added: /Users/${LOGNAME}/.ssh/id_rsa_jenkins-builder (/Users/${LOGNAME}/.ssh/id_rsa_jenkins-builder)
Lifetime set to 36000 seconds
Identity added: /Users/${LOGNAME}/.ssh/id_rsa_coreos (/Users/${LOGNAME}/.ssh/id_rsa_coreos)
Lifetime set to 36000 seconds
net.link.ether.inet.arp_unicast_lim: 0 -> 1
Establishing ssh tunnel with ${CUSTOM_LDAP_NAME}@forinf2.${CUSTOM_WORK_DOMAINS[0]}:2002...
Establishing ssh tunnel with ${CUSTOM_LDAP_NAME}@laxinf2.${CUSTOM_WORK_DOMAINS[0]}:2003...
Establishing ssh tunnel with ${LOGNAME/\.*/}@${CUSTOM_HOME_DOMAIN}:2000...
${LOGNAME/\.*/}@home.${CUSTOM_HOME_DOMAIN}'s password:
net.link.ether.inet.arp_unicast_lim: 3 -> 1
nas.${CUSTOM_NAS_HOST#*\.}:/share unmount from /Users/${LOGNAME}/Documents/share1
nas.${CUSTOM_NAS_HOST#*\.}:/share unmount from /Users/${LOGNAME}/Documents/share1
umount: unmount(/Users/${LOGNAME}/Documents/share1): Invalid argument
attempting to unmount /Users/${LOGNAME}/Documents/share1 by fsid
nas.${CUSTOM_NAS_HOST#*\.}:/share/pictures unmount from /Users/${LOGNAME}/Pictures/share1
nas.${CUSTOM_NAS_HOST#*\.}:/share/pictures unmount from /Users/${LOGNAME}/Pictures/share1
umount: unmount(/Users/${LOGNAME}/Pictures/share1): Invalid argument
attempting to unmount /Users/${LOGNAME}/Pictures/share1 by fsid
      refresh The castles dotfiles,homeshick are outdated.
        pull? [yN] y
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
${LOGNAME}@MC02RR283FVH6 ~ () $ ~/.workstation_update.sh

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

Updating gems...
Updating rubygems-update

Skipping reinstall of brew cask "virtualbox" (known issues with non-root installs at time of coding).

Updating gems...
Updating rubygems-update

Skipping reinstall of brew cask "virtualbox" (known issues with non-root installs at time of coding).

Updating gems...
Updating rubygems-update

Skipping reinstall of brew cask "virtualbox" (known issues with non-root installs at time of coding).
...

Updating installed gems
Updating bundler

Updating pip...
...

Updating gcloud...
...

```
