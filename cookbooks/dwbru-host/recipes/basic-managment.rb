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

# Users settings from list of node.json file
node['users'].each do |user|
  user user["name"] do
    username user["name"]
    comment user["fullname"]
    shell user["shell"]
    gid user["group"]
    action ( { "on" => [:create, :unlock], "off" => [:create, :lock] }[ user["status"] ] )
  end
end

# Setting hostname
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
  content "#{node.name}.#{node['domain']}"
  owner "root"
  group "root"
  mode "0644"
  action :create
end

# Settings /etc/hosts from hostname IP domain settings 
template "/etc/hosts" do
  source "hosts.erb"
  owner "root"
  group "root"
  mode 0644
  variables(
    'ip' => node["ipaddress"],
    'host' => node.name,
    'domain' => node["domain"]
  )
end

# Setting timeZone
link "/etc/localtime" do
  to "/usr/share/zoneinfo/UTC"
end

file "/etc/timezone" do
  content "UTC"
  owner "root"
  group "root"
  mode "0644"
  action :create
end

# Search domain set
template "/etc/dhcp/dhclient.conf" do
  source "dhclient.conf.erb"
  owner "root"
  group "root"
  mode 0644
  variables(
    'domain' => node["domain"]
  )
end

# Install list of packages from attributes
node["usefulPackages"].each do |pkg|
    package "#{pkg}" do
       action :install
    end
end

cookbook_file "Security updates ON" do
  source "50unattended-upgrades"
  path "/etc/apt/apt.conf.d/50unattended-upgrades"
  owner "root"
  group "root"
  mode "0644"
  action :create
end



=begin


=end
