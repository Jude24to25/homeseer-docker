#!/bin/bash -e

# Perform operations requiring root privileges
ln -snf /usr/share/zoneinfo/"$TZ" /etc/localtime && echo "$TZ" > /etc/timezone

# Setup Avahi config if needed
if [ ! -z "$DSM_HOSTNAME" ]; then
  sed "s/.*host-name.*/host-name=${DSM_HOSTNAME}/" /etc/avahi/avahi-daemon.conf > /tmp/avahi-daemon.conf.tmp && \
  mv /tmp/avahi-daemon.conf.tmp /etc/avahi/avahi-daemon.conf
else
  sed "s/.*host-name.*/#host-name=/" /etc/avahi/avahi-daemon.conf > /tmp/avahi-daemon.conf.tmp && \
  mv /tmp/avahi-daemon.conf.tmp /etc/avahi/avahi-daemon.conf
fi

# Make sure homeseer directory has proper permissions
chown -R homeseer:homeseer /homeseer

# Either:
# Option A: Switch to homeseer user and exec the original entrypoint
exec su - homeseer -c "cd /homeseer && /usr/local/sbin/homeseer"

# Or Option B: Run as root but modify the entrypoint script to skip the operations that fail
# (You would need to modify the /usr/local/sbin/homeseer script to skip timezone and avahi config)