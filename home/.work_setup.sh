#!/usr/bin/env bash
# for work specific installations and configuration
# assumes you have already run ~/.workstation_setup.sh

# custom dns per domain
[[ -d /etc/resolver ]] || sudo mkdir -pv /etc/resolver
for domain in amazonaws.com ec2.internal i.${CUSTOM_WORK_DOMAINS[0]} ${CUSTOM_WORK_DOMAINS}; do
  [[ -f /etc/resolver/${domain} ]] || \
    echo "nameserver ${CUSTOM_WORK_VPN_SERVER}" | sudo tee -a /etc/resolver/${domain}
done

# ecr login
aws ecr get-login --no-include-email | bash

# brew cask install aws-vault
brew tap versent/homebrew-taps
brew install saml2aws

brew install go-jira
# get jira api token from https://id.atlassian.com/manage/api-tokens

echo "configure node"
curl -u${NPM_REPO_LOGIN} "https://${CUSTOM_WORK_JFROG_SUBDOMAIN}.jfrog.io/${CUSTOM_WORK_JFROG_SUBDOMAIN}/api/npm/${CUSTOM_WORK_DOMAINS[0]/.com/}-npm/auth/${CUSTOM_WORK_DOMAINS[0]/.com/}" > .npmrc
# npm login ${CUSTOM_WORK_JFROG_SUBDOMAIN}.jfrog.io
# npm config set registry https://${CUSTOM_WORK_JFROG_SUBDOMAIN}.jfrog.io/${CUSTOM_WORK_JFROG_SUBDOMAIN}/api/npm/${CUSTOM_WORK_DOMAINS[0]/.com/}-npm/
npm install --global pajv
# npm install --global @${CUSTOM_WORK_DOMAINS[0]/.com/}/generator-saml2aws
npm install --global @${CUSTOM_WORK_DOMAINS[0]/.com/}/generator-master-generator
npm install --global @${CUSTOM_WORK_DOMAINS[0]/.com/}/generator-infra-pipeline
brew install ${CUSTOM_WORK_DOMAINS[0]/.com/}/public/sopstool
echo "Add the saml2aws keychain into keychain access and change timeout from 5m to 60m"
# brew cask install caskroom/cask/intellij-idea-ce

# repo specific stuff
if [[ -d ~/build/github/infrastructure ]]; then
  cd ~/build/github/infrastructure
else
  mkdir -p ~/build/github && cd ~/build/github
  git clone git@github.com:${CUSTOM_WORK_DOMAINS[0]/.com/}/infrastructure.git
  cd infrastructure
fi

echo "configure terraform"
tfenv install $(cat .terraform-version)
brew install terraform_landscape
# terraform plan ... | landscape
# OR paste output into https://chrislewisdev.github.io/prettyplan/

echo "configure ruby gems"
brew bundle
bundle install
bundle exec gem install berkshelf
gem install travis --no-rdoc

# echo "Regretfully configure chef client and virtualbox"
# brew cask install chef/chef/chefdk virtualbox

echo "configure travis"
# from a work github repo
travis login --pro
travis enable

echo "Regretfully install Checkpoint Endpoint Security VPN"
echo "download from https://supportcenter.checkpoint.com/supportcenter/portal/user/anon/page/default.psml/media-type/html?action=portlets.DCFileAction&eventSubmit_doGetdcdetails=&fileid=60048"
echo "press any key when finished..."
pause

echo "configure extra kubernetes/helm tools"
(
if [[ -d ~/build/github/ibex ]]; then
  cd ~/build/github/ibex
else
  cd ~/build/github
  git clone git@github.com:${CUSTOM_WORK_DOMAINS[0]/.com/}/ibex.git
  cd ibex
fi
asdf install
brew install octant
# helm unittest <chart_name>
go get -u github.com/kcmerrill/alfred
)

# cli
echo "Setup cli https://github.com/${CUSTOM_WORK_DOMAINS[0]/.com/}/${CUSTOM_WORK_DOMAINS[0]/.com/}_cli"
