First steps
===========

# Install additional software
apt-get update
apt-get install ruby git
gem install hub

# Cheff
curl -L https://www.getchef.com/chef/install.sh | sudo bash

# Get dwbru chef-repository
mkdir /var/chef-repo/
cd /var/chef-repo/
hub checkout dwbru/chef-repo

# Copy configurations
cp ./additional/configFiles/knife.rb ~/.chef/
cp ./additional/configFiles/client.rb /etc/chef/

# Configure node
cp ./nodes/node-template.json ./nodes/NEW-NODE-NAME.json
knife node edit NEW-NODE-NAME

# Run
chef-client
