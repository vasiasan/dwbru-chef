default["domain"] = "dwbru.net"

# Secret key path for decrypt databags of dwbru hosts
default[:dataBagSecretPath] = "/root/data_bag_secret.key"
# If used Host Used in - ec2 for specific settings.
default["ec2"] = false

# WARN used in firewall cookbook
#          "ufw",
default["usefulPackages"] = [
          "mc",
          "zsh",
          "git",
          "bash-completion",
          "command-not-found",
          "man-db",
          "iptables",
          "psmisc",
          "acl",
          "telnet",
          "wget",
          "dnsutils",
          "traceroute",
          "lsof",
          "mlocate",
          "rsync",
          "ncurses-term",
          "vim",
          "dstat",
          "apt-file",
          "makepasswd",
          "unattended-upgrades",
          "postfix",
          "bsd-mailx",
          "nginx",
          "php5-fpm",
          "php5-mysql",
          "php5-mcrypt",
          "php5-gd",
          "php5-json",
          "libapache2-mod-macro",
          "libapache2-mod-php5",
          "vsftpd"
]
