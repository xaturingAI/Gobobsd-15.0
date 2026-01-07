#!/bin/sh

# Script to mount the FreeBSD ISO file
ISO_PATH="./FreeBSD-15.0-RELEASE-amd64-dvd1.iso"
MOUNT_POINT="/tmp/cdrom_mount"

# Create mount point
mkdir -p $MOUNT_POINT

# Attach the ISO file to a memory disk device
MD_DEVICE=$(mdconfig -a -t vnode -f "$ISO_PATH")

# Try mounting with cd9660 first (traditional ISO9660)
if ! mount -t cd9660 /dev/$MD_DEVICE $MOUNT_POINT 2>/dev/null; then
    # If cd9660 fails, try ufs (in case it's a hybrid ISO)
    if ! mount -t ufs /dev/$MD_DEVICE $MOUNT_POINT 2>/dev/null; then
        # If direct mount fails, try mounting the first partition
        if ! mount -t cd9660 /dev/${MD_DEVICE}p1 $MOUNT_POINT 2>/dev/null; then
            # If that fails, try with the CD-ROM slice
            if ! mount -t cd9660 /dev/${MD_DEVICE}a $MOUNT_POINT 2>/dev/null; then
                echo "Warning: Could not mount the ISO with standard methods"
                echo "Attempting to list what's available on the device..."
                ls -la /dev/$MD_DEVICE*
                # Fallback: just show the device info
                mdconfig -lv | grep $MD_DEVICE
            fi
        fi
    fi
fi

echo "ISO attached to device: /dev/$MD_DEVICE"
echo "Mounted at: $MOUNT_POINT"

# Show what's in the mount point
if [ -d "$MOUNT_POINT" ] && [ -n "$(ls -A $MOUNT_POINT)" ]; then
    echo "Contents of mount point:"
    ls -la $MOUNT_POINT
else
    echo "Mount point is empty or doesn't exist"
    echo "Available device partitions:"
    ls -la /dev/${MD_DEVICE}*
fi