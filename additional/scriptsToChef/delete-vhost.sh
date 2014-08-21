#!/usr/bin/env bash

set -o nounset
set -o errexit
set -o verbose
set -o xtrace

if [[ "$#" != 1 ]]; then
  echo "Usage: $0 username"
  echo ""
  echo "Examples: $0 mantra"
  echo "          $0 berdsk"
  exit 1
fi

readonly VHOSTSHORT="$1"
readonly VHOSTHOME=$(getent passwd ${VHOSTSHORT} | cut -d: -f6)
readonly VHOSTLONG=$(getent passwd ${VHOSTSHORT} | cut -d: -f6 | cut -d/ -f4)
readonly PREFIX='/srv/www'
readonly NGINXCONF="/etc/nginx/sites-available/${VHOSTLONG}"
readonly NGINXSYMLINK="/etc/nginx/sites-enabled/${VHOSTLONG}"
readonly DATETIME=$(date +%F_%T)

if ! [[ "${VHOSTSHORT}" =~ ^[a-zA-Z] ]]; then
  echo "Error: username \"${VHOSTSHORT}\" must begin with a letter"
  exit 1
fi

if ! getent passwd "${VHOSTSHORT}" > /dev/null; then
  echo "Error: unix username \"${VHOSTSHORT}\" is unknown"
  exit 1
fi

if ! [[ "${VHOSTHOME}" =~ ^"${PREFIX}/".+ ]]; then
  echo "Error: home \"${VHOSTHOME}\" needs to be within prefix \"${PREFIX}\""
  exit 1
fi

if [[ -L "${NGINXSYMLINK}" ]]; then
  echo "Deleting Nginx config symlink \"${NGINXSYMLINK}\""
  rm -v "${NGINXSYMLINK}" 
  echo 'Reloading Nginx configuration'
  /etc/init.d/nginx reload
else
  echo "Nginx config symlink \"${NGINXSYMLINK}\" were not found. Skipping..."
fi

if [[ -f "${NGINXCONF}" ]]; then
  echo "Renaming Nginx config file \"${NGINXCONF}\" to \"${NGINXCONF}-deleted-at-${DATETIME}\""
  mv -i "${NGINXCONF}" "${NGINXCONF}-deleted-at-${DATETIME}"
else
  echo "Nginx config file \"${NGINXCONF}\" were not found. Skipping..."
fi

if [[ -d "${VHOSTHOME}" ]]; then
  echo "Renaming vhost home \"${VHOSTHOME}\" to \:${VHOSTHOME}-deleted-at-${DATETIME}\""
  mv -i "${VHOSTHOME}" "${VHOSTHOME}-deleted-at-${DATETIME}"
else
  echo "Vhost home \"${VHOSTHOME}\" were not found. Skipping..."
fi

echo 'Reseting quota prior to deleting user'
quotatool -u "${VHOSTSHORT}" -b -l 0 -q 0 /

echo "Deleting unix user \"${VHOSTSHORT}\""
userdel "${VHOSTSHORT}"

if getent group "${VHOSTSHORT}" > /dev/null; then
  echo "Deleting unix group \"${VHOSTSHORT}\""
  groupdel "${VHOSTSHORT}"
else
  echo "Unix group  \"${VHOSTSHORT}\" where not found. Skipping..."
fi
