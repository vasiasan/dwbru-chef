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
    action ( { "on" => :create, "off" => :remove }[ user["status"] ] )
    # Maybe auth keys here
    #notifies :create, "file[#{user}]"
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
  only_if { node['ec2'] }
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

package "mysql-server" do
  action :install
  notifies :start, "service[mysql]"
  notifies :run, "ruby_block[mysqlPasswordGeneration]"
end

service "mysql" do
  action :enable
end

ruby_block "mysqlPasswordGeneration" do
  block do

    chars = [(0..9), ('a'..'z'), ('A'..'Z')].map { |i| i.to_a }.flatten
    randomString = (0...32).map { chars[rand(chars.length)] }.join

    File.open("/root/.my.cnf", 'w') { |file| file.write("[client]\npassword=#{randomString}\n") }
    %x( mysqladmin -u root --password="" password #{randomString} )
    print "\n    ******************************************************************\n"
    print "    * New mysql root user password: #{randomString} *\n"
    print "    ******************************************************************"

  end
  action :nothing
end

cookbook_file "Security updates ON" do
  source "50unattended-upgrades"
  path "/etc/apt/apt.conf.d/50unattended-upgrades"
  owner "root"
  group "root"
  mode "0644"
  action :create
end

cookbook_file "/etc/aliases" do
  source "aliases"
  path "/etc/aliases"
  owner "root"
  group "root"
  mode "0644"
  action :create
  notifies :run, "execute[newaliases]"
end

file "/etc/postfix/catch-all-local.regexp" do
  content "!/^owner-/ admin@buddhism.ru"
  owner "root"
  group "root"
  mode "0644"
  action :create
  notifies :reload, "service[postfix]"
end

cookbook_file "/etc/postfix/main.cf" do
  source "main.cf"
  path "/etc/postfix/main.cf"
  owner "root"
  group "root"
  mode "0644"
  action :create
  notifies :reload, "service[postfix]"
end

[ "", node['fqdn']+"/logs" ].each do |path|
  directory "/srv/www/#{path}" do
    owner "root"
    group "www-data"
    mode 00750
    recursive true
  end
end

directory "/srv/www/#{node['fqdn']}" do
  owner "root"
  group "www-data"
  mode 00770
end

%w[ htdocs conf tmp ].each do |path|
  directory "/srv/www/#{node['fqdn']}/#{path}" do
    owner "www-data"
    group "www-data"
    mode 00770
  end
end

directory "/etc/ssl/localcerts" do
  owner "root"
  group "ssl-cert"
  mode 00710
end

cookbook_file "Logrotate nginx hosts" do
  source "logrotate-nginx"
  path "/etc/logrotate.d/nginx"
  owner "root"
  group "root"
  mode "0644"
  action :create
end

cookbook_file "Logrotate apache hosts" do
  source "logrotate-apache2"
  path "/etc/logrotate.d/apache2"
  owner "root"
  group "root"
  mode "0644"
  action :create
end

cookbook_file "vsftpd.conf" do
  source "vsftpd.conf"
  path "/etc/vsftpd.conf"
  owner "root"
  group "root"
  mode "0644"
  action :create
  notifies :restart, "service[vsftpd]"
end

cookbook_file "pamd-vsftpd" do
  source "pamd-vsftpd"
  path "/etc/pam.d/vsftpd"
  owner "root"
  group "root"
  mode "0644"
  action :create
  notifies :restart, "service[vsftpd]"
end

group "ftpuser" do
  action :create
  members "www-data"
end

execute "a2enmod actions rewrite vhost_alias macro" do
  action :run
end

execute "newaliases" do
  action :nothing
end

service "postfix" do
  action :nothing
end

service "vsftpd" do
  action :nothing
end

=begin
# 33 Userd for www-data in default user apache
user "www" do
  uid 33
  gid 33
  shell "/bin/bash"
  home "/srv/www"
  action :create
end

=end
