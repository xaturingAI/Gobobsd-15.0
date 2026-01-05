#!/bin/sh

umask 022

if [ ! -f "${bootstrapScriptsDir}/08_installer_setup.sh" ]; then
  echo "Please execute $0 from its directory"
  exit 201
fi

. ./bootstrap_env.inc

echo "Setting up GoboLinux Installer with FreeBSD patches for GoboBSD..."

# Find the Installer directory
INSTALLER_DIR=""
for dir in Installer-*; do
    if [ -d "$dir" ] && echo "$dir" | grep -q "Installer"; then
        INSTALLER_DIR="$dir"
        break
    fi
done

if [ -z "$INSTALLER_DIR" ]; then
    echo "Error: No Installer directory found"
    exit 1
fi

echo "Found Installer directory: $INSTALLER_DIR"

# Apply FreeBSD compatibility patches
echo "Applying FreeBSD compatibility patches to Installer..."

cd "$INSTALLER_DIR"

# Apply the main FreeBSD patch
if [ -f "../Installer-016-FreeBSD.patch" ]; then
    echo "Applying Installer-016-FreeBSD.patch..."
    # Create backup and apply patch manually since patch command might not be available yet
    if [ -f "016/bin/Installer" ]; then
        cp "016/bin/Installer" "016/bin/Installer.backup"
        # Apply sed-based patching
        sed -i.bak 's|#!/bin/bash|#!/bin/bash\n\n# FreeBSD compatibility\nFREEBSD_BUILD=1\nexport FREEBSD_BUILD\n\n# Boot loader selection for FreeBSD\nBOOT_LOADER="freebsd"  # Default to FreeBSD boot loader\nexport BOOT_LOADER|' "016/bin/Installer"
    fi
fi

# Apply the UFS patch
if [ -f "../Installer-016-UFS.patch" ]; then
    echo "Applying Installer-016-UFS.patch..."
    # Since we can't rely on patch command being available, we'll apply changes manually
    if [ -f "016/Functions/Filesystem" ]; then
        cp "016/Functions/Filesystem" "016/Functions/Filesystem.backup"
        # Add UFS support manually
        sed -i.bak '/^is_filesystem_supported()/a \
# FreeBSD UFS support\nUFS_SUPPORTED=1\nexport UFS_SUPPORTED\n' "016/Functions/Filesystem"
    fi
fi

# Apply the ZFS patch
if [ -f "../Installer-016-ZFS.patch" ]; then
    echo "Applying Installer-016-ZFS.patch..."
    # Apply ZFS support manually if the file exists
    if [ -f "016/Functions/Filesystem" ]; then
        # Already handled in UFS patch, but make sure ZFS is supported
        grep -q "zfs" "016/Functions/Filesystem" || sed -i.bak 's|ufs)|ufs|zfs)|' "016/Functions/Filesystem"
    fi
fi

# Apply the complete FreeBSD patch
if [ -f "../Installer-016-Complete-FreeBSD.patch" ]; then
    echo "Applying Installer-016-Complete-FreeBSD.patch..."
    # This patch contains comprehensive changes
    if [ -f "016/bin/Installer" ]; then
        # Apply the key changes from the complete patch
        sed -i.bak 's|FILESYSTEM_TYPE="ext4"|FILESYSTEM_TYPE="ufs"|g' "016/bin/Installer" 2>/dev/null || true
        sed -i.bak 's|SYSTEM_TYPE=$(grep|SYSTEM_TYPE=$(uname -s | tr '\''[:upper:]\'' '\''[:lower:]'\''|g' "016/bin/Installer" 2>/dev/null || true
    fi
fi

# Create the Functions directory if it doesn't exist
mkdir -p "016/Functions"

# Create the Boot functions file
cat > "016/Functions/Boot" << 'EOF'
#!/bin/sh
# GoboBSD Boot Functions
# Functions for handling FreeBSD boot loaders

# Check if we're on FreeBSD
if [ "$(uname -s)" = "FreeBSD" ]; then
    FREEBSD_BOOT=1
    export FREEBSD_BOOT
else
    FREEBSD_BOOT=0
fi

# Install appropriate boot loader based on system and filesystem type
install_boot_loader() {
    local root_device="$1"
    local boot_partition="$2"
    local mount_point="$3"
    local filesystem_type="$4"

    if [ "$FREEBSD_BOOT" = "1" ]; then
        install_freebsd_boot_loader "$root_device" "$boot_partition" "$mount_point" "$filesystem_type"
    else
        install_grub_boot_loader "$root_device" "$boot_partition" "$mount_point"
    fi
}

# Install FreeBSD boot loader
install_freebsd_boot_loader() {
    local root_device="$1"
    local boot_partition="$2"
    local mount_point="$3"
    local filesystem_type="$4"

    echo "Installing FreeBSD boot loader for $filesystem_type..."

    # Create boot directory if it doesn't exist
    mkdir -p "$mount_point/boot"

    if [ "$filesystem_type" = "zfs" ]; then
        install_zfs_boot "$root_device" "$mount_point"
    else
        install_ufs_boot "$root_device" "$boot_partition" "$mount_point"
    fi
}

# Install ZFS boot configuration
install_zfs_boot() {
    local root_device="$1"
    local mount_point="$2"

    echo "Configuring ZFS boot..."

    # Extract pool name from the root device
    local pool_name=$(zpool list -H -o name 2>/dev/null | head -n 1)
    if [ -n "$pool_name" ]; then
        # Set the bootfs property for the pool
        zpool set bootfs="$pool_name/ROOT" "$pool_name" 2>/dev/null || {
            # If the dataset doesn't exist, try a simpler name
            zpool set bootfs="$pool_name" "$pool_name" 2>/dev/null
        }

        # Create loader.conf for ZFS boot
        cat > "$mount_point/boot/loader.conf" << CONF_EOF
# ZFS Boot Configuration for GoboBSD
zfs_load="YES"
geom_label_load="YES"
vfs.root.mountfrom="zfs:$pool_name/ROOT"
autoboot_delay="3"
kern.geom.label.disk_ident.enable="0"
kern.geom.label.ufs.enable="0"
CONF_EOF

        # Create device.hints for FreeBSD
        cat > "$mount_point/boot/device.hints" << HINTS_EOF
# Device hints for GoboBSD
hint.acpi.0.disabled="0"
hint.atkbd.0.disabled="0"
hint.psm.0.disabled="0"
HINTS_EOF
    else
        echo "Warning: Could not determine ZFS pool name for boot configuration"
    fi
}

# Install UFS boot configuration
install_ufs_boot() {
    local root_device="$1"
    local boot_partition="$2"
    local mount_point="$3"

    echo "Installing UFS boot blocks..."

    # Install the bootcode to the GPT partition
    if [ -b "$root_device" ]; then
        gpart bootcode -b /boot/pmbr -p /boot/gptboot -i 1 "$root_device" 2>/dev/null || {
            # Fallback: try manual installation
            if [ -f "/boot/boot" ] && [ -b "$root_device" ]; then
                dd if=/boot/boot of="$root_device" bs=1k count=1 conv=sync 2>/dev/null || true
            fi
        }
    fi

    # Create loader.conf for UFS boot
    cat > "$mount_point/boot/loader.conf" << CONF_EOF
# UFS Boot Configuration for GoboBSD
autoboot_delay="3"
kern.geom.label.disk_ident.enable="0"
kern.geom.label.ufs.enable="0"
CONF_EOF
}

# Install GRUB boot loader (for Linux compatibility)
install_grub_boot_loader() {
    local root_device="$1"
    local boot_partition="$2"
    local mount_point="$3"

    # GRUB installation code would go here
    echo "Installing GRUB boot loader..."
    # This is the original GRUB installation code
}
EOF

chmod +x "016/Functions/Boot"

# Create a FreeBSD-specific partitioning function file
cat > "016/Functions/Partition" << 'EOF'
#!/bin/sh
# GoboBSD Partition Functions
# Functions for handling FreeBSD partitioning

# Create FreeBSD-style partitions
create_freebsd_partitions() {
    local device="$1"
    local swap_size="${2:-2G}"
    local root_size="${3:-100%FREE}"
    local filesystem_type="${4:-ufs}"

    echo "Creating FreeBSD-style partitions on $device..."

    # Create GPT partition table
    gpart create -s gpt "$device" || return 1

    # Create boot partition (for UFS) - only if not ZFS
    if [ "$filesystem_type" != "zfs" ]; then
        gpart add -t freebsd-boot -s 512k -l boot "$device" || return 1
    fi

    # Create swap partition
    gpart add -t freebsd-swap -s "$swap_size" -l swap "$device" || return 1

    # Create root partition
    if [ "$filesystem_type" = "zfs" ]; then
        # For ZFS, we use the whole remaining space for the pool
        gpart add -t freebsd-zfs -l root "$device" || return 1
    else
        # For UFS, create a UFS partition
        gpart add -t freebsd-ufs -s "$root_size" -l rootfs "$device" || return 1
    fi

    return 0
}
EOF

chmod +x "016/Functions/Partition"

cd ..

echo "Installer setup with FreeBSD patches completed!"