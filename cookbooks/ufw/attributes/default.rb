default['firewall']['rules'] = [
      { "ftp"   => { "port" => "21" } },
      { "ssh"   => { "port" => "22" } },
      { "http"  => { "port" => "80" } },
      { "https" => { "port" => "443" } },
      { "traceroute" => {
                          "port_range" => "33434..33534",
                          "protocol" => "udp"
                        }
      }
]
default['firewall']['securitylevel'] = ""
