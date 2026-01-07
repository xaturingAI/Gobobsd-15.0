#!/bin/sh

# Script to install FreeBSD kernel and base for GoboBSD
# Checks create_env.inc and other files to determine where kernel and base should go

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
status_message "  RELEASE=${RELEASE}"
status_message "  BSDREL=${BSDREL}"
status_message "  BASEDIR=${BASEDIR}"

# Check if FreeBSD base and kernel are available in a CD-ROM or download location
FREEBSD_BASE_URL="https://download.freebsd.org/releases/$(uname -m)/${RELEASE}"
FREEBSD_CDROM_PATH="/cdrom/${RELEASE}"

# Function to check if base, kernel, lib32, and src exist in a location
check_freebsd_files() {
    local base_path="$1"

    if [ -d "$base_path/base" ] && [ -d "$base_path/kernels" ]; then
        status_message "Found FreeBSD base and kernels in: $base_path"
        # Check for optional components
        if [ -d "$base_path/lib32" ]; then
            status_message "Found FreeBSD lib32 in: $base_path"
        else
            status_message "FreeBSD lib32 not found in: $base_path (this is optional)"
        fi
        if [ -d "$base_path/src" ]; then
            status_message "Found FreeBSD src in: $base_path"
        else
            status_message "FreeBSD src not found in: $base_path (this is optional)"
        fi
        return 0
    else
        status_message "FreeBSD base and kernels not found in: $base_path"
        return 1
    fi
}

# Check for FreeBSD files in various locations
FREEBSD_SOURCE=""
if check_freebsd_files "$FREEBSD_CDROM_PATH"; then
    FREEBSD_SOURCE="$FREEBSD_CDROM_PATH"
elif [ -d "./Sources/${RELEASE}" ] && check_freebsd_files "./Sources/${RELEASE}"; then
    FREEBSD_SOURCE="./Sources/${RELEASE}"
else
    status_message "FreeBSD base and kernels not found locally. Attempting to download..."
    
    # Create Sources directory if it doesn't exist
    mkdir -p ./Sources
    
    # Download FreeBSD base, kernel, lib32, and src
    status_message "Downloading FreeBSD ${RELEASE} base, kernel, lib32, and src..."

    cd ./Sources
    if [ ! -d "${RELEASE}" ]; then
        mkdir -p "${RELEASE}"
    fi

    cd "${RELEASE}"

    # Download base system
    if [ ! -f "base.txz" ]; then
        status_message "Downloading base.txz..."
        fetch "${FREEBSD_BASE_URL}/base.txz" || error_exit "Failed to download base.txz"
    else
        status_message "base.txz already exists, skipping download"
    fi

    # Download kernel
    if [ ! -f "kernel.txz" ]; then
        status_message "Downloading kernel.txz..."
        fetch "${FREEBSD_BASE_URL}/kernel.txz" || error_exit "Failed to download kernel.txz"
    else
        status_message "kernel.txz already exists, skipping download"
    fi

    # Download lib32 (optional component)
    if [ ! -f "lib32.txz" ]; then
        status_message "Downloading lib32.txz..."
        if fetch "${FREEBSD_BASE_URL}/lib32.txz"; then
            status_message "Successfully downloaded lib32.txz"
        else
            status_message "lib32.txz not available for this architecture or release, skipping"
        fi
    else
        status_message "lib32.txz already exists, skipping download"
    fi

    # Download src (optional component)
    if [ ! -f "src.txz" ]; then
        status_message "Downloading src.txz..."
        if fetch "${FREEBSD_BASE_URL}/src.txz"; then
            status_message "Successfully downloaded src.txz"
        else
            status_message "src.txz not available for this architecture or release, skipping"
        fi
    else
        status_message "src.txz already exists, skipping download"
    fi

    # Extract the archives
    status_message "Extracting base.txz..."
    if [ ! -d "base" ]; then
        mkdir -p base
        tar -xf base.txz -C base
    else
        status_message "Base already extracted, skipping"
    fi

    status_message "Extracting kernel.txz..."
    if [ ! -d "kernels" ]; then
        mkdir -p kernels
        tar -xf kernel.txz -C kernels
    else
        status_message "Kernels already extracted, skipping"
    fi

    # Extract lib32 if available
    if [ -f "lib32.txz" ] && [ ! -d "lib32" ]; then
        status_message "Extracting lib32.txz..."
        mkdir -p lib32
        tar -xf lib32.txz -C lib32
    elif [ -f "lib32.txz" ]; then
        status_message "lib32 already extracted, skipping"
    else
        status_message "Skipping lib32 extraction (not available)"
    fi

    # Extract src if available
    if [ -f "src.txz" ] && [ ! -d "src" ]; then
        status_message "Extracting src.txz..."
        mkdir -p src
        tar -xf src.txz -C src
    elif [ -f "src.txz" ]; then
        status_message "src already extracted, skipping"
    else
        status_message "Skipping src extraction (not available)"
    fi

    cd ../..
    FREEBSD_SOURCE="./Sources/${RELEASE}"
fi

# Verify that we found the FreeBSD files
if [ -z "$FREEBSD_SOURCE" ] || [ ! -d "$FREEBSD_SOURCE/base" ]; then
    error_exit "Could not locate FreeBSD base in any expected location"
fi

# Check for kernels directory with proper substructure
if [ ! -d "$FREEBSD_SOURCE/kernels" ]; then
    error_exit "Could not locate FreeBSD kernels in any expected location"
elif [ ! -d "$FREEBSD_SOURCE/kernels/boot" ] && [ ! -d "$FREEBSD_SOURCE/kernels/kernel" ]; then
    # Check if there's a kernel subdirectory like GENERIC
    KERNEL_SUBDIR_FOUND=false
    for subdir in "$FREEBSD_SOURCE/kernels"/*; do
        if [ -d "$subdir" ] && [ "$(basename "$subdir")" != "boot" ]; then
            KERNEL_SUBDIR_FOUND=true
            break
        fi
    done
    if [ "$KERNEL_SUBDIR_FOUND" = false ]; then
        error_exit "Could not locate FreeBSD kernel files in expected subdirectories"
    fi
fi

status_message "Using FreeBSD source from: $FREEBSD_SOURCE"

# Check for optional components
if [ -d "$FREEBSD_SOURCE/lib32" ]; then
    status_message "Found lib32 component in source directory"
else
    status_message "lib32 component not found (this is optional)"
fi

if [ -d "$FREEBSD_SOURCE/src" ]; then
    status_message "Found src component in source directory"
else
    status_message "src component not found (this is optional)"
fi

# Check if DESTDIR already contains files and warn the user
if [ -d "$DESTDIR" ] && [ "$(ls -A "$DESTDIR" 2>/dev/null)" ]; then
    status_message "WARNING: DESTDIR ($DESTDIR) already contains files."
    status_message "This may cause 'already-existing object' errors during installation."
    echo "Do you want to continue anyway? This may overwrite existing files. (y/N): "
    read -r response
    if [ "$response" != "y" ] && [ "$response" != "Y" ]; then
        error_exit "Installation aborted by user"
    fi
else
    status_message "Creating DESTDIR: $DESTDIR"
    mkdir -p "$DESTDIR"
fi

# Install the base system to DESTDIR
status_message "Installing FreeBSD base to $DESTDIR..."
if [ -d "$FREEBSD_SOURCE/base" ]; then
    cd "$FREEBSD_SOURCE/base"
    # FreeBSD base is typically just extracted content, install it properly
    tar -cf - . | (cd "$DESTDIR" && tar --exclude='./install.sh' -xf -)
    status_message "FreeBSD base installed successfully to $DESTDIR"
else
    error_exit "Base directory not found in source: $FREEBSD_SOURCE/base"
fi

# Install the kernel to DESTDIR
status_message "Installing FreeBSD kernel to $DESTDIR..."
if [ -d "$FREEBSD_SOURCE/kernels" ]; then
    cd "$FREEBSD_SOURCE/kernels"

    # Handle different possible kernel directory structures
    if [ -d "boot" ]; then
        # Standard FreeBSD structure: kernels/boot/ (contains kernel/ subdirectory)
        # Extract the entire boot directory to $DESTDIR/boot/
        cd "boot"
        mkdir -p "$DESTDIR/boot"
        tar -cf - . | (cd "$DESTDIR/boot" && tar -xf -)
        status_message "FreeBSD kernel installed successfully to $DESTDIR/boot/"
    elif [ -d "boot/kernel" ]; then
        # Alternative structure: kernels/boot/kernel/
        # Create the boot directory structure and extract kernel files
        mkdir -p "$DESTDIR/boot/kernel"
        cd "boot/kernel"
        tar -cf - . | (cd "$DESTDIR/boot/kernel" && tar -xf -)
        status_message "FreeBSD kernel installed successfully to $DESTDIR/boot/kernel/"
    elif [ -d "kernel" ]; then
        # Alternative structure: kernels/kernel/
        # Extract to the correct location in DESTDIR: $DESTDIR/boot/kernel/
        mkdir -p "$DESTDIR/boot/kernel"
        cd "kernel"
        tar -cf - . | (cd "$DESTDIR/boot/kernel" && tar -xf -)
        status_message "FreeBSD kernel installed successfully to $DESTDIR/boot/kernel/"
    else
        # Look for kernel subdirectories like GENERIC
        KERNEL_SUBDIR=""
        for subdir in GENERIC GENERIC.kernel kernel; do
            if [ -d "$subdir" ]; then
                KERNEL_SUBDIR="$subdir"
                break
            fi
        done

        if [ -n "$KERNEL_SUBDIR" ]; then
            # Extract to the correct location in DESTDIR: $DESTDIR/boot/kernel/
            mkdir -p "$DESTDIR/boot/kernel"
            cd "$KERNEL_SUBDIR"
            tar -cf - . | (cd "$DESTDIR/boot/kernel" && tar -xf -)
            status_message "FreeBSD kernel installed successfully to $DESTDIR/boot/kernel/"
        else
            # Try to find any subdirectory that might contain kernel files
            for subdir in */; do
                if [ -d "$subdir" ]; then
                    cd "$subdir"
                    if [ -f "kernel" ] || [ -n "$(ls -A . 2>/dev/null)" ]; then
                        mkdir -p "$DESTDIR/boot/kernel"
                        tar -cf - . | (cd "$DESTDIR/boot/kernel" && tar -xf -)
                        status_message "FreeBSD kernel installed successfully to $DESTDIR/boot/kernel/"
                        break
                    else
                        cd ..  # Go back to try the next subdirectory
                    fi
                fi
            done
        fi
    fi
else
    error_exit "Kernels directory not found in source: $FREEBSD_SOURCE/kernels"
fi

# Install the lib32 system to DESTDIR if available
if [ -d "$FREEBSD_SOURCE/lib32" ]; then
    status_message "Installing FreeBSD lib32 to $DESTDIR..."
    cd "$FREEBSD_SOURCE/lib32" || error_exit "Could not access lib32 directory"
    # lib32 is typically just extracted content, so we copy it directly to DESTDIR
    if [ -n "$DESTDIR" ]; then
        # Create lib32 directory in DESTDIR if it doesn't exist
        mkdir -p "$DESTDIR/usr/lib32"
        # Copy lib32 contents to the destination
        tar -cf - . | (cd "$DESTDIR/usr/lib32" && tar -xf -)
    fi
    status_message "FreeBSD lib32 installed successfully to $DESTDIR"
else
    status_message "Skipping lib32 installation (not available)"
fi

# Install the src to DESTDIR if available
if [ -d "$FREEBSD_SOURCE/src" ]; then
    status_message "Installing FreeBSD src to $DESTDIR..."
    cd "$FREEBSD_SOURCE/src" || error_exit "Could not access src directory"
    # src is typically just extracted content, so we copy it directly to DESTDIR
    if [ -n "$DESTDIR" ]; then
        # Create src directory structure in DESTDIR if it doesn't exist
        mkdir -p "$DESTDIR/usr/src"
        # Copy src contents to the destination
        tar -cf - . | (cd "$DESTDIR/usr/src" && tar -xf -)
    fi
    status_message "FreeBSD src installed successfully to $DESTDIR"
else
    status_message "Skipping src installation (not available)"
fi

status_message "FreeBSD base, kernel, lib32, and src installation completed successfully to $DESTDIR"

# Check if ROOTDIR already contains files and warn the user
if [ -d "$ROOTDIR" ] && [ "$(ls -A "$ROOTDIR/Programs" 2>/dev/null)" ]; then
    status_message "WARNING: ROOTDIR/Programs ($ROOTDIR/Programs) already contains files."
    status_message "This may cause issues during installation."
    echo "Do you want to continue anyway? This may overwrite existing files. (y/N): "
    read -r response
    if [ "$response" != "y" ] && [ "$response" != "Y" ]; then
        error_exit "Installation aborted by user"
    fi
else
    status_message "Creating ROOTDIR: $ROOTDIR"
    mkdir -p "$ROOTDIR"
fi

# Create the base directory structure in ROOTDIR as expected by create_rootdir.sh
status_message "Setting up base directory structure in $ROOTDIR..."
if [ ! -d "$BASEDIR" ]; then
    mkdir -p "$BASEDIR"
    mkdir -p "$BASEDIR/$BSDREL"
    ln -sf "$BSDREL" "$BASEDIR/Current"
    mkdir -p "$BASEDIR/Settings"
    status_message "Created base directory structure in $BASEDIR"
else
    status_message "Base directory structure already exists in $BASEDIR"
fi

# Create the temporary tools directory structure
if [ ! -d "$TOOLDIR" ]; then
    mkdir -p "$TOOLDIR"
    mkdir -p "$TOOLDIR/$BSDREL"
    ln -sf "$BSDREL" "$TOOLDIR/Current"
    mkdir -p "$TOOLDIR/$BSDREL/bin"
    mkdir -p "$TOOLDIR/$BSDREL/lib"
    mkdir -p "$TOOLDIR/$BSDREL/Shared"
    mkdir -p "$TOOLDIR/$BSDREL/Shared/misc"
    status_message "Created temporary tools directory structure in $TOOLDIR"
else
    status_message "Temporary tools directory structure already exists in $TOOLDIR"
fi

status_message "FreeBSD base, kernel, lib32, and src installation completed successfully!"
status_message "Base system is available in $BASEDIR/$BSDREL"
status_message "Kernel is installed in $DESTDIR/boot/"
status_message "lib32 and src components are installed in $DESTDIR (if available)"
status_message "You can now run create_rootdir.sh to continue the GoboBSD setup."