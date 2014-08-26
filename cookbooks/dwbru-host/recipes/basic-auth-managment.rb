#!/usr/bin/env ruby

# Debug envs
file "#{ENV['HOME']}/z.txt" do
  content node.name
end


cookbook_file "login withot password on system console OFF" do
  source "common-auth"
  path "/etc/pam.d/common-auth"
  owner "root"
  group "root"
  mode "0644"
  action :create
end

cookbook_file "sudo group password promt OFF" do
  source "sudoers"
  path "/etc/sudoers"
  owner "root"
  group "root"
  mode "0440"
  action :create
end

cookbook_file "group record in the created files OFF" do
  source "login.defs"
  path "/etc/login.defs"
  owner "root"
  group "root"
  mode "0644"
  action :create
end

cookbook_file "password and root ssh authentication OFF" do
  source "sshd_config"
  path "/etc/ssh/sshd_config"
  owner "root"
  group "root"
  mode "0644"
  action :create
  notifies :restart, "service[ssh]", :immediately
end

service "ssh" do
  supports :status => true, :restart => true, :reload => true
  start_command   "service ssh start"
  restart_command "service ssh restart"
## Reload not work https://github.com/TalkingQuickly/basic_security-tlq
#  reload_command  "service ssh reload"
#  action :reload
end

node['users'].each do |user|
  user user["name"] do
    username user["name"]
    comment user["fullname"]
    shell user["shell"]
    gid user["group"]
    action ( { "on" => [:create, :unlock], "off" => [:create, :lock] }[ user["status"] ] )
  end
end

file "/etc/hostname" do
  content node.name
  owner "root"
  group "root"
  mode "0644"
  action :create
  notifies :run, "execute[hostname]"
end

execute "hostname" do
  command "hostname -F /etc/hostname"
  action :nothing
end

file "/etc/mailname" do
  content "#{node.name}.#{node['domainname']}"
  owner "root"
  group "root"
  mode "0644"
  action :create
end

=begin

sudo sh -c "echo myhost > /etc/hostname"
sudo hostname -F /etc/hostname
sudo sh -c "echo myhost.fqdn > /etc/mailname"
Убеждаемся, что /etc/hosts для 127.0.0.1 указывает лишь localhost
Дописываем строчку в нашим внешним IP в /etc/hosts:
1.2.3.4	myhost.fqdn myhost

=end
