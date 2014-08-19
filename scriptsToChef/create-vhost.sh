#!/usr/bin/env bash
#
# Create new vhost

set -o nounset
set -o errexit
set -o verbose
set -o xtrace

if [[ "$#" != 3 ]]; then
    echo "Usage: $0 username main-server-name alias-for-redirects"
    echo ""
    echo "Examples: $0 mantra www.mantra.ru mantra.ru"
    echo "          $0 berdsk berdsk.buddhism.ru www.berdsk.buddhism.ru"
    exit 1
fi

readonly USERNAME="$1"
readonly VHOSTMAIN="$2"
readonly VHOSTREDIR="$3"
readonly QUOTAGB=2
readonly PREFIX='/srv/www'
readonly FTPGROUP='ftpuser'
readonly FTPPASS=$(makepasswd --chars=17)
readonly NGINXCONF="/etc/nginx/sites-available/${VHOSTMAIN}"
readonly NGINXSYMLINK="/etc/nginx/sites-enabled/${VHOSTMAIN}"
readonly LOCALCERTS='/etc/ssl/localcerts'
readonly UIDMIN=60000
readonly UIDMAX=61000
readonly HOSTNAMEFQDN=$(hostname -f)

# find first unused UID
readonly UNIXID=$(awk -F: "BEGIN { UID=${UIDMIN}-1 }; { TID=\$3; if (TID>UID && TID<${UIDMAX}) UID=TID }; END { print UID+1 }" < /etc/passwd)

# check if the users home directory does not exist
test ! -d "${PREFIX}/${VHOSTMAIN}"

# create users homes
useradd -u "${UNIXID}" -G ${FTPGROUP} -d "${PREFIX}/${VHOSTMAIN}" -U -s /usr/sbin/nologin "${USERNAME}"

(echo ${FTPPASS}; echo ${FTPPASS}) | passwd ${USERNAME}


# Create vhost hierarchy
mkdir -p ${PREFIX}/${VHOSTMAIN}/{htdocs,logs,tmp/{php-upload,php-session}}

# Vhost should own only htdocs and tmp
chown -R "${USERNAME}:${USERNAME}" ${PREFIX}/${VHOSTMAIN}/{htdocs,tmp}

# Set Regular and Default ACLs to 700
setfacl --recursive --set user::rwX,group::-,other::- "${PREFIX}/${VHOSTMAIN}/"
setfacl --recursive --modify default:user::rwX,default:group::-,default:other::- "${PREFIX}/${VHOSTMAIN}/"

# Give sudo group rwX access
setfacl --recursive --modify group:sudo:rwX,default:group:sudo:rwX "${PREFIX}/${VHOSTMAIN}/"

# Give web host rX access to htdocs and tmp
setfacl --modify group:www-data:X ${PREFIX}/${VHOSTMAIN}
setfacl --recursive --modify group:www-data:rX,default:group:www-data:rX ${PREFIX}/${VHOSTMAIN}/{htdocs,tmp}

# Let vhost user read logs
setfacl --modify user:${USERNAME}:rX,default:user:${USERNAME}:r "${PREFIX}/${VHOSTMAIN}/logs/"

echo "Where to copy htdocs from (ex: karma.buddhism.ru:/src/www/dwbru.ru/htdocs/)? [skip]"
read src
if [ "$src" ]; then
    rsync --archive --sparse --force --delay-updates --delete-after --compress-level 9 --rsync-path="sudo rsync" "${SUDO_USER}@${src}" "${PREFIX}/${VHOSTMAIN}/htdocs/"
    chown -R ${USERNAME}:${USERNAME} ${PREFIX}/${VHOSTMAIN}/htdocs/
fi

# set quota
quotatool -b -l ${QUOTAGB}g -u ${USERNAME} /

if [ -f "${LOCALCERTS}/${VHOSTMAIN}.chained.crt" ] && [ -f "${LOCALCERTS}/${VHOSTREDIR}.chained.crt" ] &&
   [ -f "${LOCALCERTS}/${VHOSTMAIN}.key" ] && [ -f "${LOCALCERTS}/${VHOSTREDIR}.key" ]; then
    readonly ADDSSL=' '
else
    readonly ADDSSL='#'
fi

# ensure nginx config does not exist yet
test ! -f $NGINXCONF

if find ${PREFIX}/${VHOSTMAIN}/htdocs -name wp-includes -type d | grep -q .; then
    ADDWP=' '
else
    ADDWP='#'
fi

cat << EOB > $NGINXCONF
server {
    include local/listen-primus-80.conf;
    ${ADDSSL}   include local/listen-primus-443-ssl.conf

    server_name testing.${VHOSTMAIN};
    server_name ${VHOSTMAIN};

    ${ADDSSL}   ssl_certificate ${LOCALCERTS}/${VHOSTMAIN}.chained.crt;
    ${ADDSSL}   ssl_certificate_key ${LOCALCERTS}/${VHOSTMAIN}.key;
    ${ADDSSL}   include local/ssl.conf;

    access_log ${PREFIX}/${VHOSTMAIN}/logs/nginx-access-${VHOSTMAIN}.log;
    error_log ${PREFIX}/${VHOSTMAIN}/logs/nginx-error-${VHOSTMAIN}.log notice;

    root ${PREFIX}/${VHOSTMAIN}/htdocs;

    include local/common.conf;
    ${ADDWP}   include local/wordpress.conf;
}

server {
    include local/listen-primus-80.conf;
    ${ADDSSL}   include local/listen-primus-443-ssl.conf

    server_name ${VHOSTREDIR};

    ${ADDSSL}   ssl_certificate ${LOCALCERTS}/${VHOSTREDIR}.chained.crt;
    ${ADDSSL}   ssl_certificate_key ${LOCALCERTS}/${VHOSTREDIR}.key;
    ${ADDSSL}   include local/ssl.conf;

    access_log ${PREFIX}/${VHOSTMAIN}/logs/nginx-access-${VHOSTMAIN}.log;
    error_log ${PREFIX}/${VHOSTMAIN}/logs/nginx-error-${VHOSTMAIN}.log notice;

    return 301 \$scheme://${VHOSTMAIN}\$request_uri;
}
EOB

cat << EOB > ${PHPFPMCONF}
[${VHOSTMAIN}]
listen = /var/php-fpm-sockets/${VHOSTMAIN}.sock
user = ${USERNAME}
group = ${USERNAME}
pm = dynamic
pm.max_children = 2
pm.start_servers = 1
pm.min_spare_servers = 1
pm.max_spare_servers = 10
chdir = /
EOB

echo "Creating Nginx config symlink \"${NGINXSYMLINK}\" pointing to \"${NGINXCONF}\""
ln -s "${NGINXCONF}" "${NGINXSYMLINK}"

echo 'Reloading Nginx configuration'
#/etc/init.d/nginx reload
#/etc/init.d/php5-fpm reload

#       php_value session.save_path /srv/www/$DOMAIN/tmp/
#       php_value upload_tmp_dir /srv/www/$DOMAIN/tmp/

echo "New virtual host has been created"
echo "  FTP server name: ${HOSTNAMEFQDN}"
echo "  FTP login name: ${USERNAME}"
echo "  FTP password: ${FTPPASS}"
echo "  File quota: ${QUOTAGB}GB"
echo "  FTP URL: ftp://${USERNAME}:${FTPPASS}@${HOSTNAMEFQDN}"

