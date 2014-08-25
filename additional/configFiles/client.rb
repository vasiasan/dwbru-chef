# Place this file to: /etc/chef/
local_mode true
cache_path File.join(File.expand_path("~"), ".chef", "cache")
chef_repo_path "/var/chef-repo/"
