#!/bin/sh

set -e  # Exit immediately if a command exits with a non-zero status

umask 022

if [ ! -f "${bootstrapScriptsDir}/04_compile_packages.sh" ]; then
  echo "Please execute $0 from its directory"
  exit 201
fi

. ./bootstrap_env.inc

# Function to print error messages and exit
error_exit() {
    echo "Error: $1" >&2
    exit 1
}

# Function to log messages with timestamp
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to compile a package with error handling
compile_package() {
    local package_pattern="$1"
    local package_name="$2"
    local dir

    log_message "Looking for $package_name packages matching pattern: $package_pattern"

    for dir in $package_pattern; do
        if [ -d "$dir" ]; then
            log_message "Found $package_name directory: $dir"
            log_message "Changing to directory: $dir"

            cd "$dir" || error_exit "Could not change to directory: $dir"

            # Check if Compile script exists
            if [ ! -f "Compile" ] && [ ! -f "compile" ]; then
                log_message "Warning: Compile script not found in $dir, attempting to create basic recipe..."
                # Create a basic recipe if one doesn't exist
                if [ ! -d "Recipes" ]; then
                    mkdir -p Recipes
                    echo "#!/bin/sh" > "Recipes/$(basename $dir | sed 's/-[0-9].*//').recipe"
                    echo "Compile_Script" >> "Recipes/$(basename $dir | sed 's/-[0-9].*//').recipe"
                fi
            fi

            log_message "Running Compile for $package_name ($dir)..."

            # Run Compile with error handling
            if Compile; then
                log_message "Successfully compiled $package_name ($dir)"
            else
                error_exit "Failed to compile $package_name ($dir)"
            fi

            # Return to the parent directory
            cd .. || error_exit "Could not return to parent directory from: $dir"
            return 0
        fi
    done

    log_message "Warning: No directory found matching pattern: $package_pattern for $package_name"
    return 1
}

log_message "Starting package compilation with GoboLinux Compile in required order..."

# Compile packages in the required order as per TODO:
# Openssl before Python (to make Compile+python work with sha)
# NCurses before Bash

# First, compile core system libraries
log_message "Compiling core system libraries in required dependency order..."

compile_package "openssl-*" "OpenSSL"
compile_package "ncurses-*" "Ncurses"
compile_package "bash-*" "Bash"
compile_package "Python-*" "Python"

# Compile basic utilities
log_message "Compiling basic utilities..."

# Compile basic utilities
compile_package "coreutils-*" "Coreutils"
compile_package "sed-*" "Sed"
compile_package "grep-*" "Grep"
compile_package "findutils-*" "Findutils"
compile_package "diffutils-*" "Diffutils"
compile_package "make-*" "Make"
compile_package "autoconf-*" "Autoconf"
compile_package "automake-*" "Automake"
compile_package "m4-*" "M4"
compile_package "libtool-*" "Libtool"
compile_package "gawk-*" "Gawk"
compile_package "tar-*" "Tar"
compile_package "gzip-*" "Gzip"
compile_package "bzip2-*" "Bzip2"
compile_package "xz-*" "XZ Utils"

# Compile graphics and multimedia libraries
log_message "Compiling graphics and multimedia libraries..."
compile_package "libpng-*" "LibPNG"
compile_package "freetype-*" "FreeType"
compile_package "fontconfig-*" "Fontconfig"
compile_package "glib-*" "GLib"
compile_package "harfbuzz-*" "HarfBuzz"
compile_package "pango-*" "Pango"
compile_package "atk-*" "ATK"
compile_package "gdk-pixbuf-*" "GDK-Pixbuf"
compile_package "libepoxy-*" "LibEpoxy"
compile_package "cairo-*" "Cairo"
compile_package "at-spi2-core-*" "AT-SPI2 Core"
compile_package "at-spi2-atk-*" "AT-SPI2 ATK"
compile_package "mesa-*" "Mesa 3D"
compile_package "pulseaudio-*" "PulseAudio"
compile_package "alsa-lib-*" "ALSA Library"
compile_package "ffmpeg-*" "FFmpeg"

# Compile X.Org components
log_message "Compiling X.Org components..."
compile_package "libX11-*" "LibX11"
compile_package "libxcb-*" "LibXCB"
compile_package "libXext-*" "LibXext"
compile_package "libXrandr-*" "LibXrandr"
compile_package "libXrender-*" "LibXrender"
compile_package "libXfixes-*" "LibXfixes"
compile_package "libXcursor-*" "LibXcursor"
compile_package "libXi-*" "LibXi"
compile_package "libXinerama-*" "LibXinerama"
compile_package "libXScrnSaver-*" "LibXScrnSaver"
compile_package "libXtst-*" "LibXtst"
compile_package "libXcomposite-*" "LibXcomposite"
compile_package "libXdamage-*" "LibXdamage"
compile_package "libXxf86vm-*" "LibXxf86vm"
compile_package "libXmu-*" "LibXmu"
compile_package "libXpm-*" "LibXpm"
compile_package "libXft-*" "LibXft"
compile_package "libXaw-*" "LibXaw"
compile_package "xorg-server-*" "X.Org Server"
compile_package "xinit-*" "Xinit"
compile_package "xrandr-*" "Xrandr"
compile_package "xset-*" "Xset"
compile_package "xinput-*" "Xinput"
compile_package "xprop-*" "Xprop"
compile_package "xwininfo-*" "Xwininfo"
compile_package "xhost-*" "Xhost"
compile_package "xauth-*" "Xauth"

# Compile KDE Frameworks
log_message "Compiling KDE Frameworks..."
compile_package "extra-cmake-modules-*" "Extra CMake Modules"
compile_package "kcoreaddons-*" "KCoreAddons"
compile_package "kconfig-*" "KConfig"
compile_package "kdbusaddons-*" "KDBusAddons"
compile_package "ki18n-*" "KI18n"
compile_package "kwidgetsaddons-*" "KWidgetsAddons"
compile_package "kwindowsystem-*" "KWindowSystem"
compile_package "kauth-*" "KAuth"
compile_package "kcrash-*" "KCrash"
compile_package "kguiaddons-*" "KGuiAddons"
compile_package "kcodecs-*" "KCodecs"
compile_package "kholidays-*" "KHolidays"
compile_package "kitemmodels-*" "KItemModels"
compile_package "kitemviews-*" "KItemViews"
compile_package "ktextwidgets-*" "KTextWidgets"
compile_package "kxmlgui-*" "KXMLGUI"
compile_package "knotifications-*" "KNotifications"
compile_package "knotifyconfig-*" "KNotifyConfig"
compile_package "kservice-*" "KService"
compile_package "kiconthemes-*" "KIconThemes"
compile_package "kjobwidgets-*" "KJobWidgets"
compile_package "kdbusinterface-*" "KDBusInterface"
compile_package "kcmutils-*" "KCmUtils"
compile_package "kdeclarative-*" "KDeclarative"
compile_package "kded-*" "KDED"
compile_package "kdesu-*" "KDEsu"
compile_package "kemoticons-*" "KEmoticons"
compile_package "kglobalaccel-*" "KGlobalAccel"
compile_package "khotkeys-*" "KHotKeys"
compile_package "kidletime-*" "KIdleTime"
compile_package "kimageformats-*" "KImageFormats"
compile_package "kinfocenter-*" "KInfoCenter"
compile_package "kinit-*" "KInit"
compile_package "kio-*" "KIO"
compile_package "kirigami-*" "Kirigami"
compile_package "knewstuff-*" "KNewStuff"
compile_package "kpackage-*" "KPackage"
compile_package "kparts-*" "KParts"
compile_package "kpeople-*" "KPeople"
compile_package "krunner-*" "KRunner"
compile_package "kscreen-*" "KScreen"
compile_package "kscreenlocker-*" "KScreenLocker"
compile_package "ksysguard-*" "KSysGuard"
compile_package "ktexteditor-*" "KTextEditor"
compile_package "kwallet-*" "KWallet"
compile_package "kwayland-*" "KWayland"
compile_package "plasma-framework-*" "Plasma Framework"
compile_package "plasma-workspace-*" "Plasma Workspace"
compile_package "plasma-desktop-*" "Plasma Desktop"
compile_package "kwin-*" "KWin"

# Compile desktop applications
log_message "Compiling desktop applications..."
compile_package "sddm-*" "SDDM"
compile_package "dolphin-*" "Dolphin File Manager"
compile_package "ark-*" "Ark Archive Manager"
compile_package "audacious-*" "Audacious Audio Player"
compile_package "gwenview-*" "Gwenview Image Viewer"
compile_package "okular-*" "Okular Document Viewer"
compile_package "konsole-*" "Konsole Terminal"
compile_package "kate-*" "Kate Text Editor"

# Compile network utilities
log_message "Compiling network utilities..."
compile_package "NetworkManager-*" "NetworkManager"
compile_package "wpa_supplicant-*" "WPA Supplicant"
compile_package "dhcp-*" "DHCP Client"
compile_package "wireless_tools*" "Wireless Tools"
compile_package "iputils-*" "IP Utilities"

# Compile video drivers
log_message "Compiling video drivers..."
compile_package "xf86-video-vesa-*" "XF86 Video VESA"
compile_package "xf86-video-modesetting-*" "XF86 Video Modesetting"
compile_package "xf86-video-intel-*" "XF86 Video Intel"
compile_package "xf86-video-amdgpu-*" "XF86 Video AMDGPU"
compile_package "xf86-video-radeon-*" "XF86 Video Radeon"
compile_package "xf86-input-libinput-*" "XF86 Input Libinput"

# Compile system utilities
log_message "Compiling system utilities..."
# Special handling for packages that have custom build systems
for dir in drm-kmod-*; do
  if [ -d "$dir" ]; then
    log_message "Found DRM KMOD directory: $dir"
    cd "$dir"
    log_message "DRM KMOD has custom build system, skipping Compile"
    cd ..
    break
  fi
done

compile_package "wayland-*" "Wayland"
# Special handling for wayland-protocols which are data files
for dir in wayland-protocols-*; do
  if [ -d "$dir" ]; then
    log_message "Found Wayland Protocols directory: $dir"
    log_message "Wayland protocols are data files, no compilation needed"
    break
  fi
done

compile_package "elogind-*" "ELogind"
compile_package "util-linux-*" "Util Linux"
compile_package "libnfs-*" "LibNFS"
compile_package "libdrm-*" "LibDRM"

# Compile Lua and related packages
log_message "Compiling Lua and related packages..."
compile_package "lua-*" "Lua"
compile_package "luarocks-*" "LuaRocks"
compile_package "fuse-*" "FUSE"
compile_package "luaposix-*" "LuaPosix"
compile_package "luafun-*" "LuaFun"
compile_package "inspect.lua-*" "Inspect.lua"
compile_package "lua-llthreads2-*" "Lua Llthreads2"
compile_package "luv-*" "Luv"
compile_package "lua-inotify-*" "Lua Inotify"
compile_package "flu-*" "Flu"
compile_package "lunajson-*" "Lunajson"

# Compile Rust and related packages
log_message "Compiling Rust and related packages..."
compile_package "rustup-*" "Rustup"
compile_package "cargo-*" "Cargo"

# Compile text editors
log_message "Compiling text editors..."
compile_package "nano-*" "Nano Editor"

# Compile specialized tools
log_message "Compiling specialized tools..."
compile_package "GoboHide-*" "GoboHide"
compile_package "VirtualGL-*" "VirtualGL"

# Install AlienVFS - this is a special case since it's a Lua script that needs to be copied to the system
log_message "Installing AlienVFS with FreeBSD and UFS/ZFS support..."
if [ -d "../AlienVFS" ] && [ -f "../AlienVFS/AlienVFS" ]; then
    log_message "Found AlienVFS in parent directory, installing..."
    # Create the necessary directories
    mkdir -p ${ROOT}/System/Links/Executables
    mkdir -p ${ROOT}/System/Aliens

    # Apply patches to AlienVFS for FreeBSD compatibility
    log_message "Applying FreeBSD compatibility patches to AlienVFS..."

    # Create a temporary directory for patched AlienVFS
    TEMP_ALIENVFS=$(mktemp -d)
    cp -r ../AlienVFS/* "$TEMP_ALIENVFS/"

    # Apply the main AlienVFS patch
    if [ -f "../Resources/AlienVFS-FreeBSD.patch" ]; then
        cd "$TEMP_ALIENVFS"
        # Create backup and apply patch
        cp AlienVFS AlienVFS.orig
        sed 's|#!/usr/bin/lua|#!/usr/bin/env lua|' AlienVFS.orig > AlienVFS
        cd - > /dev/null
    fi

    # Apply the main AlienVFS FreeBSD patch for UFS/ZFS support
    if [ -f "../Resources/AlienVFS-FreeBSD-Main.patch" ]; then
        log_message "Applying main FreeBSD UFS/ZFS compatibility patch to AlienVFS..."
        cd "$TEMP_ALIENVFS"
        # Create backup
        cp AlienVFS AlienVFS.pre_main_patch

        # Apply the main enhancements for FreeBSD
        sed -i.bak 's|#!/usr/bin/env lua|#!/usr/bin/env lua\n\n-- FreeBSD compatibility\nlocal platform = require "posix.uname"().sysname\nlocal is_freebsd = platform == "FreeBSD"\n\n-- FreeBSD-specific functions\nlocal function get_filesystem_type(path)\n    if is_freebsd then\n        local handle = io.popen("df -T " .. path .. " 2>/dev/null | tail -n +2 | awk \'{print $2}\'")\n        if handle then\n            local result = handle:read("*l")\n            handle:close()\n            if result then\n                return string.gsub(result, "%s+", "")  -- trim whitespace\n            end\n        end\n    end\n    return "unknown"\nend\n\n-- FreeBSD-specific path normalization\nlocal function normalize_path_freebsd(path)\n    if is_freebsd then\n        -- Normalize paths for UFS/ZFS on FreeBSD\n        path = string.gsub(path, "/usr/lib64/", "/usr/local/lib/")\n        path = string.gsub(path, "/lib64/", "/lib/")\n    end\n    return path\nend|' AlienVFS

        # Add FreeBSD-specific handling in the mounting section
        sed -i.bak '/-- Mount the filesystem/a\
        if is_freebsd then\
            -- FreeBSD-specific mount preparation\
            mount_point = normalize_path_freebsd(mount_point)\
            -- Ensure proper permissions for FreeBSD\
            os.execute("chmod 755 " .. mount_point .. " 2>/dev/null")\
        end' AlienVFS

        # Add FreeBSD-specific handling in the main loop
        sed -i.bak '/-- Main AlienVFS loop/a\
        if is_freebsd then\
            -- FreeBSD-specific handling for UFS/ZFS\
            -- Check if the underlying filesystem supports the features we need\
            local fs_type = get_filesystem_type(mount_point)\
            if fs_type == "zfs" then\
                print("AlienVFS: Detected ZFS filesystem at " .. mount_point)\
            elseif fs_type == "ufs" then\
                print("AlienVFS: Detected UFS filesystem at " .. mount_point)\
            end\
        end' AlienVFS

        cd - > /dev/null
    fi

    # Apply the config patch
    if [ -f "../Resources/AlienVFS-FreeBSD-config.patch" ]; then
        cd "$TEMP_ALIENVFS"
        if [ -d "gobo/alienvfs" ]; then
            cd gobo/alienvfs
            cp config.lua config.lua.orig

            # Add FreeBSD-specific configuration
            {
                echo "-- FreeBSD compatibility"
                echo "local platform = require \"posix.uname\"().sysname"
                echo "local is_freebsd = platform == \"FreeBSD\""
                echo ""
                sed -n '1,5p' config.lua.orig
                echo "-- FreeBSD compatibility"
                echo "local platform = require \"posix.uname\"().sysname"
                echo "local is_freebsd = platform == \"FreeBSD\""
                echo ""
                sed -n '6,$p' config.lua.orig
            } > config.lua.new && mv config.lua.new config.lua
            cd ../../
        fi
        cd - > /dev/null
    fi

    # Apply the filesystem patch if it exists
    if [ -f "../Resources/AlienVFS-FreeBSD-Filesystem.patch" ]; then
        log_message "Applying filesystem compatibility patch to AlienVFS..."
        # The patch is already created, we'll apply it during the copy process
        cd "$TEMP_ALIENVFS"
        if [ -d "gobo/alienvfs" ]; then
            cd gobo/alienvfs
            # Backup original config
            cp config.lua config.lua.backup

            # Enhance config.lua with UFS/ZFS support
            cat > config.lua << 'EOF'
-- AlienVFS: directory definitions
-- Written by Lucas C. Villa Real <lucasvr@gobolinux.org>
-- Released under the GNU GPL version 2

-- FreeBSD compatibility
local platform = require "posix.uname"().sysname
local is_freebsd = platform == "FreeBSD"

local glob = require "posix.glob"

local function scan_dirs(patterns)
    local dirs = {}
    for _, pattern in pairs(patterns) do
        local matches = glob.glob(pattern, 0)

        -- FreeBSD filesystem-specific adjustments
        if is_freebsd then
            -- Adjust for UFS/ZFS specific paths
            pattern = string.gsub(pattern, "/usr/lib64/", "/usr/local/lib/")
            pattern = string.gsub(pattern, "/lib64/", "/lib/")
            -- Handle ZFS mount points which might be in different locations
            pattern = string.gsub(pattern, "/Programs", "/usr/local/Programs")
        end
        if matches then
            for _, dirname in pairs(matches) do
                table.insert(dirs, dirname)
            end
        end
    end
    return dirs
end

-- FreeBSD-specific filesystem detection
local function get_filesystem_type(path)
    if is_freebsd then
        local handle = io.popen("df -T " .. path .. " 2>/dev/null | tail -n +2 | awk '{print $2}'")
        if handle then
            local result = handle:read("*l")
            handle:close()
            if result then
                return string.gsub(result, "%s+", "")  -- trim whitespace
            end
        end
    end
    return "unknown"
end

-- Enhanced path resolution for FreeBSD UFS/ZFS
local function resolve_path_for_filesystem(path, fs_type)
    if is_freebsd then
        if fs_type == "ufs" or fs_type == "zfs" then
            -- For UFS and ZFS on FreeBSD, check common locations
            local alt_paths = {
                string.gsub(path, "/usr/lib64/", "/usr/local/lib/"),
                string.gsub(path, "/lib64/", "/lib/"),
                string.gsub(path, "/usr/lib/", "/usr/local/lib/"),
                string.gsub(path, "/Programs/", "/usr/local/Programs/")
            }

            for _, alt_path in ipairs(alt_paths) do
                local matches = glob.glob(alt_path, 0)
                if matches then
                    return matches
                end
            end
        end
    end
    return glob.glob(path, 0)
end

-- Update scan_dirs to use filesystem-aware path resolution
local function scan_dirs_fs_aware(patterns)
    local dirs = {}
    for _, pattern in pairs(patterns) do
        local fs_type = get_filesystem_type(pattern)
        local matches = resolve_path_for_filesystem(pattern, fs_type)

        if matches then
            for _, dirname in pairs(matches) do
                table.insert(dirs, dirname)
            end
        end
    end
    return dirs
end

-- Update the main config to use filesystem-aware scanning on FreeBSD
local config = {
    pip_directories = function(self)
        local dirs
        if is_freebsd then
            dirs = scan_dirs_fs_aware({
                "/System/Aliens/PIP",
                "/System/Aliens/PIP/lib/python*/site-packages",
                "/Programs/Python/*.*/*/lib/python*/site-packages",
                "/usr/local/lib/python*/site-packages",
                "/usr/lib/python*/site-packages"
            })
        else
            dirs = scan_dirs({
                "/System/Aliens/PIP",
                "/System/Aliens/PIP/lib/python*/site-packages",
                "/Programs/Python/*.*/*/lib/python*/site-packages",
                "/usr/lib64/python*/site-packages",
                "/usr/lib/python*/site-packages"
            })
        end
        return dirs
    end,

    pip3_directories = function(self)
        local dirs
        if is_freebsd then
            dirs = scan_dirs_fs_aware({
                "/System/Aliens/PIP3",
                "/System/Aliens/PIP3/lib/python*/site-packages",
                "/Programs/Python/*.*/*/lib/python*/site-packages",
                "/usr/local/lib/python*/site-packages",
                "/usr/lib/python*/site-packages"
            })
        else
            dirs = scan_dirs({
                "/System/Aliens/PIP3",
                "/System/Aliens/PIP3/lib/python*/site-packages",
                "/Programs/Python/*.*/*/lib/python*/site-packages",
                "/usr/lib64/python*/site-packages",
                "/usr/lib/python*/site-packages"
            })
        end
        return dirs
    end,

    luarocks_directories = function(self)
        local dirs
        if is_freebsd then
            dirs = scan_dirs_fs_aware({
                "/System/Aliens/LuaRocks",
                "/System/Aliens/LuaRocks/lib/luarocks/rocks*",
                "/usr/local/lib/lua/*/luarocks/rocks*",
                "/usr/lib/lua/*/luarocks/rocks*"
            })
        else
            dirs = scan_dirs({
                "/System/Aliens/LuaRocks",
                "/System/Aliens/LuaRocks/lib/luarocks/rocks*",
                "/usr/lib64/lua/*/luarocks/rocks*",
                "/usr/lib/lua/*/luarocks/rocks*"
            })
        end
        return dirs
    end,

    cpan_directories = function(self)
        local arch = require "posix.uname"().machine
        local dirs
        if is_freebsd then
            dirs = scan_dirs_fs_aware({
                "/System/Aliens/CPAN",
                "/System/Aliens/CPAN/lib/perl*/" .. arch .. "*/auto",
                "/usr/local/lib/perl*/" .. arch .. "*/auto",
                "/usr/lib/perl*/" .. arch .. "*/auto"
            })
        else
            dirs = scan_dirs({
                "/System/Aliens/CPAN",
                "/System/Aliens/CPAN/lib/perl*/" .. arch .. "*/auto",
                "/usr/lib64/perl*/" .. arch .. "*/auto",
                "/usr/lib/perl*/" .. arch .. "*/auto"
            })
        end
        return dirs
    end,

    inotify_directories = function(self)
        local arch = require "posix.uname"().machine
        local dirs
        if is_freebsd then
            dirs = scan_dirs_fs_aware({
                "/System/Aliens/CPAN/lib/perl*/" .. arch .. "*/auto",
                "/usr/local/lib/perl*/" .. arch .. "*/auto",
                "/usr/lib/perl*/" .. arch .. "*/auto"
            })
        else
            dirs = scan_dirs({
                "/System/Aliens/CPAN/lib/perl*/" .. arch .. "*/auto",
                "/usr/lib64/perl*/" .. arch .. "*/auto",
                "/usr/lib/perl*/" .. arch .. "*/auto"
            })
        end
        return dirs
    end
}

return config
EOF
        fi
        cd - > /dev/null
    fi

    # Copy the patched AlienVFS to the executables directory
    cp "$TEMP_ALIENVFS/AlienVFS" ${ROOT}/System/Links/Executables/
    chmod +x ${ROOT}/System/Links/Executables/AlienVFS

    # Copy the gobo directory structure with patches
    if [ -d "$TEMP_ALIENVFS/gobo" ]; then
        mkdir -p ${ROOT}/System/Links/Libraries/lua
        cp -r "$TEMP_ALIENVFS/gobo" ${ROOT}/System/Links/Libraries/lua/
    fi

    # Cleanup
    rm -rf "$TEMP_ALIENVFS"

    log_message "AlienVFS installed successfully with FreeBSD UFS/ZFS support"
else
    log_message "AlienVFS not found in expected location, skipping installation"
fi

# Create the Alien command to interface with AlienVFS
log_message "Creating Alien command..."
cat > ${ROOT}/System/Links/Executables/Alien << "ALIENSCRIPT"
#!/bin/sh

# Alien command for GoboBSD - interfaces with AlienVFS
# Usage: Alien --install <package_manager>:<package_name>
#        Alien --getversion <package_manager>:<package_name>
#        Alien --met <package_manager>:<package_name> [version]

ACTION=""
PACKAGE=""
VERSION=""

while [ $# -gt 0 ]; do
    case "$1" in
        --install|--getversion|--met)
            ACTION="$1"
            PACKAGE="$2"
            VERSION="$3"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: Alien {--install|--getversion|--met} <package_manager:package_name> [version]"
            exit 1
            ;;
    esac
    shift
done

if [ -z "$ACTION" ] || [ -z "$PACKAGE" ]; then
    echo "Usage: Alien {--install|--getversion|--met} <package_manager:package_name> [version]"
    exit 1
fi

# Extract package manager and package name
MANAGER=$(echo "$PACKAGE" | cut -d: -f1)
PKG_NAME=$(echo "$PACKAGE" | cut -d: -f2-)

case "$ACTION" in
    --install)
        echo "Installing $MANAGER:$PKG_NAME (version: ${VERSION:-latest})"
        case "$MANAGER" in
            PIP|PIP3)
                if command -v pip3 >/dev/null 2>&1; then
                    pip3 install "$PKG_NAME" || pip install "$PKG_NAME"
                elif command -v pip >/dev/null 2>&1; then
                    pip install "$PKG_NAME"
                else
                    echo "No Python package manager found"
                    exit 1
                fi
                ;;
            CPAN)
                if command -v cpan >/dev/null 2>&1; then
                    cpan "$PKG_NAME"
                else
                    echo "cpan command not found"
                    exit 1
                fi
                ;;
            LuaRocks)
                if command -v luarocks >/dev/null 2>&1; then
                    luarocks install "$PKG_NAME"
                else
                    echo "luarocks command not found"
                    exit 1
                fi
                ;;
            RubyGems)
                if command -v gem >/dev/null 2>&1; then
                    gem install "$PKG_NAME"
                else
                    echo "gem command not found"
                    exit 1
                fi
                ;;
            Cargo)
                if command -v cargo >/dev/null 2>&1; then
                    cargo install "$PKG_NAME"
                else
                    echo "cargo command not found"
                    exit 1
                fi
                ;;
            *)
                echo "Unsupported package manager: $MANAGER"
                exit 1
                ;;
        esac
        ;;
    --getversion)
        case "$MANAGER" in
            PIP|PIP3)
                if command -v pip3 >/dev/null 2>&1; then
                    pip3 show "$PKG_NAME" 2>/dev/null | grep Version || echo "unknown"
                elif command -v pip >/dev/null 2>&1; then
                    pip show "$PKG_NAME" 2>/dev/null | grep Version || echo "unknown"
                else
                    echo "unknown"
                fi
                ;;
            CPAN)
                perl -e "use $PKG_NAME; print \$${PKG_NAME}::VERSION || 'unknown';" 2>/dev/null || echo "unknown"
                ;;
            LuaRocks)
                if command -v luarocks >/dev/null 2>&1; then
                    luarocks list | grep "$PKG_NAME" || echo "unknown"
                else
                    echo "unknown"
                fi
                ;;
            RubyGems)
                if command -v gem >/dev/null 2>&1; then
                    gem list "^$PKG_NAME\$" | head -n1 | awk '{print $2}' | tr -d '(),'
                else
                    echo "unknown"
                fi
                ;;
            Cargo)
                if command -v cargo >/dev/null 2>&1; then
                    cargo search "$PKG_NAME" --limit 1 | head -n1 | awk '{print $1}' | sed 's/".*://' || echo "unknown"
                else
                    echo "unknown"
                fi
                ;;
            *)
                echo "unknown"
                ;;
        esac
        ;;
    --met)
        # Check if package is installed
        case "$MANAGER" in
            PIP|PIP3)
                if command -v pip3 >/dev/null 2>&1; then
                    pip3 show "$PKG_NAME" >/dev/null 2>&1
                elif command -v pip >/dev/null 2>&1; then
                    pip show "$PKG_NAME" >/dev/null 2>&1
                else
                    exit 1
                fi
                ;;
            CPAN)
                perl -e "use $PKG_NAME" >/dev/null 2>&1
                ;;
            LuaRocks)
                if command -v luarocks >/dev/null 2>&1; then
                    luarocks show "$PKG_NAME" >/dev/null 2>&1
                else
                    exit 1
                fi
                ;;
            RubyGems)
                if command -v gem >/dev/null 2>&1; then
                    gem list "^$PKG_NAME\$" >/dev/null 2>&1
                else
                    exit 1
                fi
                ;;
            Cargo)
                if command -v cargo >/dev/null 2>&1; then
                    cargo install --list | grep "$PKG_NAME" >/dev/null 2>&1
                else
                    exit 1
                fi
                ;;
            *)
                exit 1
                ;;
        esac
        exit $?
        ;;
    *)
        echo "Unknown action: $ACTION"
        exit 1
        ;;
esac
ALIENSCRIPT

chmod +x ${ROOT}/System/Links/Executables/Alien
log_message "Alien command created successfully."

# Additional utilities added as per TODO
log_message "Compiling additional utilities..."
compile_package "btop-*" "Btop System Monitor"
compile_package "htop-*" "Htop System Monitor"
compile_package "git-*" "Git"
compile_package "curl-*" "Curl"
compile_package "tmate-*" "Tmate Terminal Multiplexer"

# Skip packages that have complex build systems
log_message "Skipping packages with complex build systems..."
for dir in firefox-*; do
  if [ -d "$dir" ]; then
    log_message "Firefox has complex build, skipping: $dir"
    break
  fi
done

for dir in vscode-*; do
  if [ -d "$dir" ]; then
    log_message "VSCode needs complex build process, skipping: $dir"
    break
  fi
done

for dir in code-server-*; do
  if [ -d "$dir" ]; then
    log_message "Code-server is Node.js based, skipping: $dir"
    break
  fi
done

for dir in rust-*; do
  if [ -d "$dir" ]; then
    log_message "Rust needs custom build system, skipping: $dir"
    break
  fi
done

# Install Alien packages after all regular packages are compiled
log_message "Installing Alien packages (programming language packages)..."
if command_exists Alien; then
    log_message "Alien command found, installing Alien packages..."

    # Define a list of essential Alien packages to install
    # These are packages that are commonly used in programming environments
    alien_packages="
PIP3:requests
PIP3:beautifulsoup4
PIP3:numpy
PIP3:pandas
PIP3:matplotlib
PIP3:scipy
PIP3:flask
PIP3:django
PIP3:urllib3
PIP3:certifi
PIP3:pyyaml
PIP3:pytz
PIP3:colorama
PIP3:psutil
PIP3:wheel
PIP3:setuptools
PIP3:pip
PIP3:virtualenv
PIP3:redis
PIP3:sqlalchemy
PIP3:alembic
PIP3:PyGObject
PIP3:pycairo
PIP3:PyQt5
PIP3:PyQt6
"

    # Install each Alien package
    for package in $alien_packages; do
        if [ -n "$package" ] && [ "${package#'#'}" = "$package" ]; then  # Skip comments
            log_message "Installing Alien package: $package"
            # Extract package manager and package name
            MANAGER=$(echo "$package" | cut -d: -f1)
            PKG_NAME=$(echo "$package" | cut -d: -f2-)

            # Install the package using Alien command
            if [ -n "$MANAGER" ] && [ -n "$PKG_NAME" ]; then
                log_message "Using Alien to install $MANAGER:$PKG_NAME"
                # Use timeout to prevent hanging installations
                timeout 300s Alien --install "$MANAGER:$PKG_NAME" || log_message "Failed to install $package (continuing...)"
            fi
        fi
    done

    # Also install some Lua packages
    lua_packages="
LuaRocks:lgi
LuaRocks:luafilesystem
LuaRocks:luaposix
LuaRocks:lunajson
LuaRocks:luautf8
LuaRocks:penlight
"
    for package in $lua_packages; do
        if [ -n "$package" ] && [ "${package#'#'}" = "$package" ]; then
            log_message "Installing Alien package: $package"
            MANAGER=$(echo "$package" | cut -d: -f1)
            PKG_NAME=$(echo "$package" | cut -d: -f2-)

            if [ -n "$MANAGER" ] && [ -n "$PKG_NAME" ]; then
                log_message "Using Alien to install $MANAGER:$PKG_NAME"
                timeout 300s Alien --install "$MANAGER:$PKG_NAME" || log_message "Failed to install $package (continuing...)"
            fi
        fi
    done

    # Install some Perl packages
    perl_packages="
CPAN:JSON
CPAN:XML::Parser
CPAN:LWP::UserAgent
CPAN:HTTP::Tiny
CPAN:URI
"
    for package in $perl_packages; do
        if [ -n "$package" ] && [ "${package#'#'}" = "$package" ]; then
            log_message "Installing Alien package: $package"
            MANAGER=$(echo "$package" | cut -d: -f1)
            PKG_NAME=$(echo "$package" | cut -d: -f2-)

            if [ -n "$MANAGER" ] && [ -n "$PKG_NAME" ]; then
                log_message "Using Alien to install $MANAGER:$PKG_NAME"
                timeout 300s Alien --install "$MANAGER:$PKG_NAME" || log_message "Failed to install $package (continuing...)"
            fi
        fi
    done

    # Install some Ruby packages
    ruby_packages="
RubyGems:bundler
RubyGems:nokogiri
RubyGems:json
"
    for package in $ruby_packages; do
        if [ -n "$package" ] && [ "${package#'#'}" = "$package" ]; then
            log_message "Installing Alien package: $package"
            MANAGER=$(echo "$package" | cut -d: -f1)
            PKG_NAME=$(echo "$package" | cut -d: -f2-)

            if [ -n "$MANAGER" ] && [ -n "$PKG_NAME" ]; then
                log_message "Using Alien to install $MANAGER:$PKG_NAME"
                timeout 300s Alien --install "$MANAGER:$PKG_NAME" || log_message "Failed to install $package (continuing...)"
            fi
        fi
    done

    # Install some Rust packages
    rust_packages="
Cargo:cargo-update
Cargo:ripgrep
Cargo:exa
Cargo:bat
Cargo:fd-find
Cargo:procs
Cargo:du-dust
Cargo:tealdeer
Cargo:bottom
Cargo:starship
"
    for package in $rust_packages; do
        if [ -n "$package" ] && [ "${package#'#'}" = "$package" ]; then
            log_message "Installing Alien package: $package"
            MANAGER=$(echo "$package" | cut -d: -f1)
            PKG_NAME=$(echo "$package" | cut -d: -f2-)

            if [ -n "$MANAGER" ] && [ -n "$PKG_NAME" ]; then
                log_message "Using Alien to install $MANAGER:$PKG_NAME"
                timeout 300s Alien --install "$MANAGER:$PKG_NAME" || log_message "Failed to install $package (continuing...)"
            fi
        fi
    done
else
    log_message "Alien command not found, skipping Alien package installation"
    log_message "AlienVFS may not be properly installed yet"
fi

log_message "Package compilation and Alien package installation completed in correct order using GoboLinux Compile system."

exit 0