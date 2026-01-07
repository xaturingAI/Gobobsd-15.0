#!/bin/sh

# Script to unmount the FreeBSD ISO file
MOUNT_POINT="/tmp/cdrom_mount"

# Get the device name from the mount point
MD_DEVICE=$(mount | grep "$MOUNT_POINT" | grep -o 'dev/[a-z0-9]*' | head -1 | cut -d'/' -f2)

if [ -n "$MD_DEVICE" ]; then
    # Force unmount if normal unmount fails
    if ! umount $MOUNT_POINT 2>/dev/null; then
        echo "Normal unmount failed, trying force unmount..."
        umount -f $MOUNT_POINT 2>/dev/null || {
            echo "Force unmount also failed"
            echo "Checking if the mount point is still in use..."
            lsof +D $MOUNT_POINT 2>/dev/null || echo "No processes using the mount point"
        }
    fi

    # Detach the memory disk device
    mdconfig -d -u $MD_DEVICE 2>/dev/null || {
        echo "Could not detach device $MD_DEVICE, trying with force..."
        mdconfig -d -u $MD_DEVICE -f 2>/dev/null || echo "Force detach also failed"
    }

    # Remove mount point if it's empty
    if [ -d "$MOUNT_POINT" ]; then
        rmdir $MOUNT_POINT 2>/dev/null || echo "Could not remove mount point $MOUNT_POINT (may not be empty)"
    fi

    echo "ISO unmount process completed"
else
    echo "Could not find mounted ISO at $MOUNT_POINT"
    echo "Checking for any mounted ISOs..."
    mount | grep cd9660
    # Try to find any attached ISOs that might not be mounted
    mdconfig -lv | grep -i freebsd
fi