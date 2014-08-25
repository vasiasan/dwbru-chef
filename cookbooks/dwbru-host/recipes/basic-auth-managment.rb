#!/usr/bin/env ruby

file "#{ENV['HOME']}/z.txt" do
  content node['hostname']
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

cookbook_file "prohibit group record in the created files" do
  source "login.defs"
  path "/etc/login.defs"
  owner "root"
  group "root"
  mode "0644"
  action :create
end

cookbook_file "Disable password and root ssh authentication" do
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

=begin

#sudo useradd -c "First Last" -s /bin/bash -G sudo,adm -U -m mylogin

user #{node[main-user]} do
  username #{node[main-user]}
  comment
  shell
  gid
  action :create
end

=end
