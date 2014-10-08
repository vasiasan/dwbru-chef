First steps
===========

Install additional software
```bash
sudo apt-get update
sudo apt-get install ruby git
sudo gem install hub
```

Install cheff
```bash
sudo curl -L https://www.getchef.com/chef/install.sh | sudo bash
```

Get dwbru chef-repository
```bash
cd /var/
sudo git clone https://github.com/dwbru/chef-repo
cd /var/chef-repo
```

Copy configurations
```bash
sudo mkdir /root/.chef/
sudo cp ./additional/configFiles/knife.rb /root/.chef/

sudo mkdir /etc/chef/
sudo cp ./additional/configFiles/client.rb /etc/chef/
```

Configure node
```bash
sudo cp ./nodes/node-template.json ./nodes/NEW-NODE-NAME.json
sudo knife node edit NEW-NODE-NAME
```

Run
```bash
sudo chef-client -N NEW-NODE-NAME
```

Host add
===========

Generate password
```
openssl passwd -1 "theplaintextpassword"  # $1$HASHOFPASSWORD
```

Creating a host in an encrypted data bag.
```
sudo knife data bag create dwbru-hosts achinsk --secret-file ~/data_bag_secret.key
{
  "id": "achinsk",
  "password": "$1$HASHOFPASSWORD",
  "mysqlPass": "CLEANPASSWORD",
  "status": "on"
}
```

Run
```bash
sudo chef-client -N NEW-NODE-NAME
```

Basic elements
==============
[Admin creation](https://github.com/dwbru/chef-repo/blob/master/cookbooks/dwbru-host/recipes/basic-managment.rb#L66-97)

[Mysql root password generation](https://github.com/dwbru/chef-repo/blob/master/cookbooks/dwbru-host/recipes/basic-managment.rb#L177-203)

[Host creation](https://github.com/dwbru/chef-repo/blob/master/cookbooks/dwbru-host/recipes/basic-managment.rb#L339-427)

Documentation for mainly used resources
=======================================

######[All resources](http://docs.getchef.com/resource.html)

Files with hard-coded content
[Coockbook file resource](http://docs.getchef.com/resource_cookbook_file.html)

Files with free content
[File resource](http://docs.getchef.com/resource_file.html)

Resource for install or remove packages
[Package resource](http://docs.getchef.com/resource_package.html)

Resource for start|stop and enable|disable services
[Service resource](http://docs.getchef.com/resource_service.html)
