#!/bin/sh

# Script to clean up installation directories before re-running install.sh
# This addresses the "Operation not permitted" issue when trying to delete files

set -e  # Exit immediately if a command exits with a non-zero status

# Function to print error messages and exit
error_exit() {
    echo "Error: $1" >&2
    exit 1
}

# Function to print status messages
status_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Check if create_env.inc exists
if [ ! -f "create_env.inc" ]; then
    error_exit "create_env.inc not found in current directory"
fi

# Source the environment variables
. create_env.inc || error_exit "Failed to source create_env.inc"

status_message "Environment variables loaded:"
status_message "  DESTDIR=${DESTDIR}"
status_message "  ROOTDIR=${ROOTDIR}"
status_message "  BOOTDIR=${BOOTDIR}"

# Clean up Sources directory (contains downloaded FreeBSD files)
SOURCES_DIR="./Sources/${RELEASE}"
if [ -d "$SOURCES_DIR" ]; then
    status_message "Cleaning up Sources directory: $SOURCES_DIR"
    # Try to remove with standard rm first
    if [ -w "$SOURCES_DIR" ]; then
        rm -rf "$SOURCES_DIR" 2>/dev/null || {
            status_message "Standard deletion failed for Sources directory"
            # Try with doas and more forceful options
            echo "Attempting forceful deletion with doas..."
            if command -v chflags >/dev/null 2>&1; then
                # On FreeBSD, files might have immutable flags - try to clear them
                doas chflags -R noschg,nounlnk "$SOURCES_DIR" 2>/dev/null || true
                doas chflags -R 0 "$SOURCES_DIR" 2>/dev/null || true
            fi
            doas rm -rf "$SOURCES_DIR" 2>/dev/null || {
                status_message "Forceful deletion also failed for Sources directory"
                echo "Some files may require manual intervention to remove."
                echo "Try running: doas chflags -R noschg,nounlnk $SOURCES_DIR && doas rm -rf $SOURCES_DIR"
            }
        }
    else
        status_message "No write permission to Sources directory, attempting with doas"
        # Try with doas and more forceful options
        if command -v chflags >/dev/null 2>&1; then
            # On FreeBSD, files might have immutable flags - try to clear them
            doas chflags -R noschg,nounlnk "$SOURCES_DIR" 2>/dev/null || true
            doas chflags -R 0 "$SOURCES_DIR" 2>/dev/null || true
        fi
        doas rm -rf "$SOURCES_DIR" 2>/dev/null || {
            status_message "Forceful deletion failed for Sources directory"
            echo "Some files may require manual intervention to remove."
            echo "Try running: doas chflags -R noschg,nounlnk $SOURCES_DIR && doas rm -rf $SOURCES_DIR"
        }
    fi
else
    status_message "Sources directory does not exist: $SOURCES_DIR"
fi

# Clean up DESTDIR
if [ -n "$DESTDIR" ] && [ "$DESTDIR" != "/" ]; then  # Safety check to avoid accidental root deletion
    status_message "Attempting to clean up DESTDIR: $DESTDIR"
    if [ -d "$DESTDIR" ]; then
        # Try to remove with standard rm first
        if [ -w "$DESTDIR" ]; then
            rm -rf "$DESTDIR" 2>/dev/null || {
                status_message "Standard deletion failed for DESTDIR: $DESTDIR"
                # Try with doas and more forceful options for FreeBSD files
                echo "Attempting forceful deletion with doas..."
                if command -v chflags >/dev/null 2>&1; then
                    # On FreeBSD, files might have immutable flags - try to clear them
                    doas chflags -R noschg,nounlnk "$DESTDIR" 2>/dev/null || true
                    doas chflags -R 0 "$DESTDIR" 2>/dev/null || true
                fi
                # Try to remove any existing files in the directory first
                doas find "$DESTDIR" -delete 2>/dev/null || {
                    # If find fails, try with rm as a fallback
                    doas rm -rf "$DESTDIR"/* "$DESTDIR"/.[^.]* 2>/dev/null || {
                        # If all else fails, try to unmount any potential mounts in the directory
                        status_message "Attempting to unmount any potential mounts in $DESTDIR"
                        doas umount -f "$DESTDIR"/* 2>/dev/null || true
                        doas umount -f "$DESTDIR" 2>/dev/null || true
                        # Final attempt to remove the directory
                        doas rm -rf "$DESTDIR" 2>/dev/null || {
                            status_message "Forceful deletion also failed for DESTDIR: $DESTDIR"
                            echo "Some files may require manual intervention to remove."
                            echo "Try running: doas chflags -R noschg,nounlnk $DESTDIR && doas find $DESTDIR -delete"
                            echo "Or: doas umount -f $DESTDIR && doas chflags -R noschg,nounlnk $DESTDIR && doas rm -rf $DESTDIR"
                        }
                    }
                }
            }
        else
            status_message "No write permission to DESTDIR, attempting with doas"
            # Try with doas and more forceful options for FreeBSD files
            if command -v chflags >/dev/null 2>&1; then
                # On FreeBSD, files might have immutable flags - try to clear them
                doas chflags -R noschg,nounlnk "$DESTDIR" 2>/dev/null || true
                doas chflags -R 0 "$DESTDIR" 2>/dev/null || true
            fi
            # Try to remove any existing files in the directory first
            doas find "$DESTDIR" -delete 2>/dev/null || {
                # If find fails, try with rm as a fallback
                doas rm -rf "$DESTDIR"/* "$DESTDIR"/.[^.]* 2>/dev/null || {
                    # If all else fails, try to unmount any potential mounts in the directory
                    status_message "Attempting to unmount any potential mounts in $DESTDIR"
                    doas umount -f "$DESTDIR"/* 2>/dev/null || true
                    doas umount -f "$DESTDIR" 2>/dev/null || true
                    # Final attempt to remove the directory
                    doas rm -rf "$DESTDIR" 2>/dev/null || {
                        status_message "Forceful deletion failed for DESTDIR: $DESTDIR"
                        echo "Some files may require manual intervention to remove."
                        echo "Try running: doas chflags -R noschg,nounlnk $DESTDIR && doas find $DESTDIR -delete"
                        echo "Or: doas umount -f $DESTDIR && doas chflags -R noschg,nounlnk $DESTDIR && doas rm -rf $DESTDIR"
                    }
                }
            }
        fi
    else
        status_message "DESTDIR does not exist: $DESTDIR"
    fi
else
    status_message "DESTDIR is not set or appears invalid, skipping"
fi

# Clean up BASEDIR subdirectories that were created by install.sh
if [ -n "$BASEDIR" ] && [ "$BASEDIR" != "/" ]; then
    status_message "Attempting to clean up BASEDIR: $BASEDIR"
    if [ -d "$BASEDIR" ]; then
        # Remove the BSDREL subdirectory and Current symlink
        if [ -L "$BASEDIR/Current" ]; then
            rm -f "$BASEDIR/Current" 2>/dev/null || {
                echo "Could not remove $BASEDIR/Current, may need doas"
            }
        fi
        if [ -d "$BASEDIR/$BSDREL" ]; then
            rm -rf "$BASEDIR/$BSDREL" 2>/dev/null || {
                echo "Could not remove $BASEDIR/$BSDREL, may need doas"
            }
        fi
        if [ -d "$BASEDIR/Settings" ]; then
            rm -rf "$BASEDIR/Settings" 2>/dev/null || {
                echo "Could not remove $BASEDIR/Settings, may need doas"
            }
        fi
    fi
fi

# Clean up TOOLDIR subdirectories that were created by install.sh
if [ -n "$TOOLDIR" ] && [ "$TOOLDIR" != "/" ]; then
    status_message "Attempting to clean up TOOLDIR: $TOOLDIR"
    if [ -d "$TOOLDIR" ]; then
        # Remove the BSDREL subdirectory and Current symlink
        if [ -L "$TOOLDIR/Current" ]; then
            rm -f "$TOOLDIR/Current" 2>/dev/null || {
                echo "Could not remove $TOOLDIR/Current, may need doas"
            }
        fi
        if [ -d "$TOOLDIR/$BSDREL" ]; then
            rm -rf "$TOOLDIR/$BSDREL" 2>/dev/null || {
                echo "Could not remove $TOOLDIR/$BSDREL, may need doas"
            }
        fi
    fi
fi

status_message "Cleanup attempt completed."
status_message "If you still have permission issues, you may need to run:"
status_message "doas chflags -R noschg,nounlnk $DESTDIR $SOURCES_DIR && doas rm -rf $DESTDIR $ROOTDIR/Programs/FreeBSD $ROOTDIR/Programs/TemporaryTools $SOURCES_DIR"