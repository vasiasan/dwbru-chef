#!/usr/bin/env ruby

# Debug envs
#file "#{ENV['HOME']}/z.txt" do
#  content node.name
#end

# for check attribute changed can use this hack (is unchecked)
#last = Chef::Node.load(node.name)
#if last.default[‘some-attribute’] != node.default[‘some-attribute’]
    # do something
#end

#log "Hello, world!"

# Require for mysql password hash check and for idempotence execute sql query
require 'digest/md5'
  digest = Digest::MD5.hexdigest("Hello World\n")

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
data_bag('admins').each do |login|
  user = data_bag_item('admins', login)
  homedir = "/home/#{login}"
  user login do
    home homedir
    comment user["fullname"]
    shell user["shell"]
    gid user["group"]
    action ( { "on" => :create, "off" => :remove }[ user["status"] ] )
    system false
    supports :manage_home=>false
    # Maybe auth keys here
    #notifies :create, "file[#{user}]"
  end

  if user['status'] == "on" && user["ssh_keys"] then
    directory "#{homedir}/.ssh" do
      owner login
      group user["group"]
      mode "00700"
      recursive true
    end
    file "#{homedir}/.ssh/authorized_keys" do
      content user['ssh_keys'].join("\n")
      owner login
      group user["group"]
      mode "00600"
      action :create
    end
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
  action [ :enable, :start ]
end

ruby_block "mysqlPasswordGeneration" do
  block do

    chars = [(0..9), ('a'..'z'), ('A'..'Z')].map { |i| i.to_a }.flatten
    randomString = (0...32).map { chars[rand(chars.length)] }.join

    #%x( mysqladmin -u root --password="" password #{randomString} )
    # Changed by better
    mysqlPass = Chef::Resource::Execute.new("mysqladmin -u root --password="" password #{randomString}", run_context)
    mysqlPass.run_action :run

    # File.open("/root/.my.cnf", 'w') { |file| file.write("[client]\npassword=#{randomString}\n") }
    # Changed by better
    mycnfFile = Chef::Resource::File.new("/root/.my.cnf", run_context)
    mycnfFile.content "[client]\npassword=#{randomString}\n"
    mycnfFile.owner "root"
    mycnfFile.group "root"
    mycnfFile.mode "00600"
    mycnfFile.run_action :create

    print "\n    **************************************************************\n"
    print "    * New mysql roots password: #{randomString} *\n"
    print "    **************************************************************\n\n"

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

service "vsftpd" do
  action [ :enable, :start ]
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

service "nginx" do
  action [ :enable, :start ]
end

service "php5-fpm" do
  action [ :enable, :start ]
end

# http://habrahabr.ru/post/100961/
cookbook_file "php.ini cgi.fix_pathinfo=0 fix" do
  source "php.ini"
  path "/etc/php5/fpm/php.ini"
  owner "root"
  group "root"
  mode "0644"
  action :create
  notifies :restart, "service[nginx]"
end

directory "/var/run/php5-fpm/" do
  owner "root"
  group "root"
  mode "00755"
  recursive true
end

# Create dwbru hosts dir, users and configurations for nginx and php-fpm
hostsSecret = Chef::EncryptedDataBagItem.load_secret("#{node[:dataBagSecretPath]}")

data_bag('dwbru-hosts').each do |hostname|
  host = Chef::EncryptedDataBagItem.load('dwbru-hosts', hostname, hostsSecret)
  hostsdir = "/srv/www/"

  mysqlPassRegenFile = "#{hostsdir}#{hostname}/MysqlPasswordRegen"

  # Use 750 rights from 5 solution of there http://agapoff.name/vsftpd-oops.html
  directory "#{hostsdir}#{hostname}" do
    owner "root"
    group "www-data"
    mode "00750"
  end

  file mysqlPassRegenFile do
    content Digest::SHA512.hexdigest( host['mysqlPass'] )
    owner "root"
    group "root"
    mode "0600"
    action :nothing
  end

  mysqlUserDbQuery = "CREATE DATABASE IF NOT EXISTS #{hostname};
    GRANT ALL PRIVILEGES ON #{hostname}.* TO #{hostname}@'%' IDENTIFIED BY '#{host['mysqlPass']}' WITH GRANT OPTION;"

  execute 'mysql create user pass and database' do
    command "mysql --batch --silent << END\n\n #{mysqlUserDbQuery} \n\nEND"
    notifies :create, "file[#{mysqlPassRegenFile}]"
    not_if { ::File.open(mysqlPassRegenFile, "rb").read == Digest::SHA512.hexdigest( host['mysqlPass'] ) }
  end

  user hostname do
    gid "www-data"
    home "#{hostsdir}#{hostname}"
    shell "/nonexistent"
    password host["password"]
  end

#  execute "echo #{hostname}:#{randomString} | chpasswd -c SHA512" do
#    action :run
#  end


  [ "", "#{hostname}/logs" ].each do |path|
    directory "#{hostsdir}#{path}" do
      owner "root"
      group "www-data"
      mode "00750"
      recursive true
    end
  end

  %w[ htdocs conf tmp ].each do |path|
    directory "#{hostsdir}#{hostname}/#{path}" do
      owner "www-data"
      group "www-data"
      mode "00770"
    end
  end

  template "/etc/php5/fpm/pool.d/#{hostname}.conf" do
    source "php5-fpm.erb"
    owner "root"
    group "root"
    mode 0644
    variables(
      'hostname' => hostname
    )
    action :create
    notifies :restart, "service[php5-fpm]"
  end

  template "/etc/nginx/sites-available/#{hostname}" do
    source "nginx-host.erb"
    owner "root"
    group "root"
    mode 0644
    variables(
      'hostname' => hostname
    )
    action :create
    notifies :restart, "service[nginx]"
  end

  link "/etc/nginx/sites-enabled/#{hostname}" do
    to "/etc/nginx/sites-available/#{hostname}"
  end
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
