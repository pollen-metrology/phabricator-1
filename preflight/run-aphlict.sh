#!/bin/bash

set -e
set -x

# Source configuration
source /config.saved

# Touch log file and PID file to make sure they're writable
touch /var/log/aphlict.log
chown "$PHABRICATOR_DAEMON_USER:wwwgrp-phabricator" /var/log/aphlict.log

# Copy ws module from global install
cp -Rv /usr/lib/node_modules /srv/phabricator/phabricator/support/aphlict/server/
chown -Rv "$PHABRICATOR_DAEMON_USER:wwwgrp-phabricator" /srv/phabricator/phabricator/support/aphlict/server/node_modules

# Configure the Phabricator notification server
cat >/srv/aphlict.conf <<EOF
{
  "servers": [
    {
      "type": "client",
      "port": 22280,
      "listen": "127.0.0.1",
      "ssl.key": null,
      "ssl.cert": null,
      "ssl.chain": null
    },
    {
      "type": "admin",
      "port": 22281,
      "listen": "127.0.0.1",
      "ssl.key": null,
      "ssl.cert": null,
      "ssl.chain": null
    }
  ],
  "logs": [
    {
      "path": "/dev/stdout"
    }
  ],
  "pidfile": "/run/watch/aphlict"
}
EOF

# Aphlict needs write access to this directory
chmod a+rwX /run/watch

# Start the Phabricator notification server
pushd /srv/phabricator/phabricator
exec sudo -u "$PHABRICATOR_DAEMON_USER" bin/aphlict debug --config=/srv/aphlict.conf
