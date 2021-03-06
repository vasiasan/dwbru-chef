First steps
===========

Install essential  software
```bash
sudo apt-get update
sudo apt-get --no-install-recommends install ruby git
```

Install chef
```bash
sudo curl -L https://www.getchef.com/chef/install.sh | sudo bash
```

Generate new deployment key for new box
```bash
sudo ssh-keygen -t ecdsa -C "$HOSTNAME-chef-repo-deploy-key" -f /root/.ssh/id_rsa-chef-repo
sudo ssh-keygen -y -f /root/.ssh/id_rsa-chef-repo
```

Add result public key to https://github.com/dwbru/chef-repo/settings/keys

Configure git over ssh at 443 to github
```bash
cat << EOF > /root/.ssh/config
Host github.com
  Hostname ssh.github.com
  Port 443
  User git
  IdentityFile /root/.ssh/id_rsa-chef-repo
EOF
```
Get dwbru chef-repository
```bash
cd /var/
sudo git clone git@github.com:dwbru/chef-repo.git
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
sudo cp ./nodes/node-template.json ./nodes/$HOSTNAME.json
sudo knife node edit $HOSTNAME
```

Run
```bash
sudo chef-client -N $HOSTNAME
```

Secret key add
===========
***Dangerous, you can destroy the existing key. Remove "!" symbol from the name of the key.***
```
sudo openssl rand -base64 512 | tr -d '\r\n' > ~/data_bag_secret!.key
```

Host add
===========
Creating a host in an encrypted data bag.
```
sudo knife data bag create dwbru-hosts achinsk --secret-file ~/data_bag_secret.key
{
  "id": "achinsk",
  "ssh_keys": [ "PUBLIC KEYS FROM USER OF THIS HOST" ],
  "mysqlPass": "CLEANPASSWORD",
  "status": "on"
}
```

Run
```bash
sudo chef-client
```

Admin add
===========

Creating a host in an encrypted data bag.
```
sudo knife data bag create admins vasia
{
    "id": "vasia",
    "name": "vasia",
    "status": "on",
    "fullname": "Vasiliy Sannikov",
    "shell": "/bin/bash",
    "group": "sudo",
    "ssh_keys": [
      "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAgEA2MO3eQ6ZuGX0kN5ndlCWXhMqiLRLXOfmsPwMb4MBvg0ktqzkGZIC4IY5PNgIktTBloKoCcNLDBq/BwnJroOyPj4X1VybjjsQKdZUAPRZOsp0YcezfD0LlyClMGdqTIWAYT52SaQ+$
    ]
  }
```

Run
```bash
sudo chef-client
```

Big elements in code
====================
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
