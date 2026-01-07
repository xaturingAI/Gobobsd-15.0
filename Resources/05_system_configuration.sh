#!/bin/sh

umask 022

if [ ! -f "${bootstrapScriptsDir}/05_system_configuration.sh" ]; then
  echo "Please execute $0 from its directory"
  exit 201
fi

. ./bootstrap_env.inc

echo "Configuring system services for GoboBSD..."

# Create necessary directories in the GoboBSD structure
mkdir -p ${ROOT}/System/Settings
mkdir -p ${ROOT}/System/Variable
mkdir -p ${ROOT}/System/Variable/db/pkg
mkdir -p ${ROOT}/System/Variable/log
mkdir -p ${ROOT}/System/Variable/run
mkdir -p ${ROOT}/System/Variable/lock
mkdir -p ${ROOT}/System/Setup

# Configure network for FreeBSD
echo "Configuring network services..."

# Create rc.conf for FreeBSD services
cat > ${ROOT}/System/Variable/etc/rc.conf << "EOF"
# GoboBSD FreeBSD rc.conf

# Enable network
ifconfig_DEFAULT="DHCP"

# Enable SSH server
sshd_enable="YES"

# Enable periodic scripts
periodic_enable="YES"

# Enable system logger
syslogd_enable="YES"

# Enable cron
cron_enable="YES"

# Enable powerd
powerd_enable="YES"

# Enable moused
moused_enable="YES"
moused_program="/usr/sbin/moused"
moused_flags="-I"

# Enable dbus for desktop environment
dbus_enable="YES"

# Enable hald (Hardware Abstraction Layer)
hald_enable="YES"

# Enable CUPS for printing (if installed)
# cupsd_enable="YES"

# Enable network-related services
netif_enable="YES"
routing_enable="YES"
ipv6_activate_all_interfaces="NO"

# Enable for SDDM display manager
# This will be enabled after SDDM is properly configured
sddm_enable="NO"

# Enable virtualization support
vboxdrv_enable="YES"

# Enable FUSE for GoboHide and other FUSE-based utilities
fuse_load="YES"
EOF

# Create devfs rules for X11 and virtualization
cat > ${ROOT}/System/Variable/etc/devfs.rules << "EOF"
# GoboBSD devfs rules for X11 and virtualization
[localrules=10]
add path 'drm/*' mode 0666 group wheel
add path 'dri/*' mode 0666 group wheel
add path 'nvidia*' mode 0666 group wheel
add path 'nvidiactl' mode 0666 group wheel
add path 'vboxdrv' mode 0666 group wheel
add path 'vboxdrvu' mode 0666 group wheel
add path 'vmm/*' mode 0666 group wheel
EOF

# Create modules file for kernel modules needed by desktop
cat > ${ROOT}/System/Variable/etc/rc.conf.d/modules << "EOF"
kld_list="amdgpu i915 vboxdrv vboxnetadp vboxnetflt"
EOF

# Create a script to enable SDDM after the system is fully set up
cat > ${ROOT}/System/Setup/enable_sddm.sh << "EOF"
#!/bin/sh
# Script to enable SDDM after all packages are installed

# Enable SDDM in rc.conf
sed -i '' 's/sddm_enable="NO"/sddm_enable="YES"/' /System/Variable/etc/rc.conf

# Create SDDM configuration directory
mkdir -p /System/Settings/sddm.conf.d

# Create basic SDDM configuration
cat > /System/Settings/sddm.conf.d/gobobsd.conf << "SDDMCONF"
[X11]
EnableHiDPI=false

[Wayland]
Enable=true

[Users]
MaximumUid=60000
MinimumUid=1000
SuspendIndicators=0

[Autologin]
Relogin=false
SDDMCONF

# Add SDDM to the startup sequence
echo "SDDM display manager enabled"
EOF

chmod +x ${ROOT}/System/Setup/enable_sddm.sh

# Create a basic hosts file
cat > ${ROOT}/System/Variable/etc/hosts << "EOF"
127.0.0.1	localhost
::1		localhost
EOF

# Create resolv.conf to allow DNS resolution
cp /etc/resolv.conf ${ROOT}/System/Variable/etc/resolv.conf

# Create a script to set up proper symlinks for system configuration
cat > ${ROOT}/System/Setup/setup_system_links.sh << "EOF"
#!/bin/sh
# Script to create proper symlinks for system configuration in GoboBSD

# Create necessary etc directory if it doesn't exist
mkdir -p /etc

# Create symlinks for system configuration files
ln -sf /System/Variable/etc/rc.conf /etc/rc.conf
ln -sf /System/Variable/etc/hosts /etc/hosts
ln -sf /System/Variable/etc/resolv.conf /etc/resolv.conf
ln -sf /System/Variable/etc/devfs.rules /etc/devfs.rules

# Create directories for services if they don't exist
mkdir -p /var/db/pkg
mkdir -p /var/log
mkdir -p /var/run
mkdir -p /var/lock

# Create symlinks for variable directories
ln -sf /System/Variable/db/pkg /var/db/pkg
ln -sf /System/Variable/log /var/log
ln -sf /System/Variable/run /var/run
ln -sf /System/Variable/lock /var/lock

# Create necessary device directories
mkdir -p /dev
mkdir -p /proc

echo "System configuration links created."
EOF

chmod +x ${ROOT}/System/Setup/setup_system_links.sh

echo "System configuration completed."

exit 0
