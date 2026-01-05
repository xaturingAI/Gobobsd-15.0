#!/bin/sh

# Make sure superuser is using correct home directory
pw usermod -u 0 -c "SuperUser" -d /Users/root

# Add essential groups for FreeBSD system
pw groupadd wheel -g 0 || true  # wheel group (already exists as gid 0)
pw groupadd operator -g 5 || true  # operator group
pw groupadd video -g 600 || true  # video group for graphics access
pw groupadd users -g 100 || true

# Add live user with proper groups
# Note that since bash isn't installed yet, sh will
# have to do as shell for now
pw groupadd live -g 21 || true
pw useradd live -u 21 -g live -G wheel,operator,video -c "Live user" -d /tmp -s sh || \
pw usermod live -u 21 -g live -G wheel,operator,video -c "Live user" -d /tmp -s sh

# Set default base directory for new users
# Require passwords for new users in order to login
# Default shell is sh (will be changed to zsh when
# it has been installed)
# Default primary group is new group named after user
pw useradd -D -u 1000,32000 -b /Users -w no -s sh -g ""

# Remove unnecessary symlink that was setup by create_rootdir.sh
if [ -L /root ]; then
  rm /root
fi

exit 0
