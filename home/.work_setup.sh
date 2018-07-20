#!/usr/bin/env bash
# for work specific installations and configuration
# assumes you have already run ~/.workstation_setup.sh

docker login ${CUSTOM_WORK_JFROG_SUBDOMAIN}.jfrog.io

brew cask install aws-vault

echo "configure node"
curl -u${NPM_REPO_LOGIN} "https://${CUSTOM_WORK_JFROG_SUBDOMAIN}.jfrog.io/${CUSTOM_WORK_JFROG_SUBDOMAIN}/api/npm/${CUSTOM_WORK_DOMAINS[0]/.com/}-npm/auth/${CUSTOM_WORK_DOMAINS[0]/.com/}" > .npmrc
# npm login ${CUSTOM_WORK_JFROG_SUBDOMAIN}.jfrog.io
npm install --global yo yarn
npm install --global @${CUSTOM_WORK_DOMAINS[0]/.com/}/generator-aws-vault
brew install ${CUSTOM_WORK_DOMAINS[0]/.com/}/public/sopstool
yo @${CUSTOM_WORK_DOMAINS[0]/.com/}/aws-vault
echo "Add the aws-vault keychain into keychain access and change timeout from 5m to 60m"
brew cask install caskroom/cask/intellij-idea-ce

echo "configure ruby gems"
(
[[ -d ~/build/github/infrastructure ]]; then
  cd ~/build/github/infrastructure
else
  mkdir -p ~/build/github && cd ~/build/github
  git clone git@github.com:${CUSTOM_WORK_DOMAINS[0]/.com/}/infrastructure.git
  cd infrastructure
fi
brew bundle
bundle install
bundle exec gem install berkshelf
)

echo "configure travis"
# from an work github repo
travis login --pro
travis enable

echo "Install Checkpoint Endpoint Security VPN"
echo "download from https://supportcenter.checkpoint.com/supportcenter/portal/user/anon/page/default.psml/media-type/html?action=portlets.DCFileAction&eventSubmit_doGetdcdetails=&fileid=60048"
echo "press any key when finished..."
pause