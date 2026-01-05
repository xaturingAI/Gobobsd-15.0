#!/bin/sh

set -e  # Exit immediately if a command exits with a non-zero status

# Function to print error messages and exit
error_exit() {
    echo "Error: $1" >&2
    exit 1
}

# Function to validate directory creation
ensure_directory() {
    if [ ! -d "$1" ]; then
        if ! mkdir -p "$1"; then
            error_exit "Failed to create directory: $1"
        fi
    fi
}

cd $(dirname $(which $0)) || error_exit "Failed to determine script directory"
SCRIPTDIR=$(pwd) || error_exit "Failed to get current directory"

# Validate that create_env.inc exists
if [ ! -f "create_env.inc" ]; then
    error_exit "create_env.inc not found in current directory"
fi

. create_env.inc || error_exit "Failed to source create_env.inc"

ftpGnu=https://ftp.gnu.org/gnu

ensure_directory ./Sources
cd ./Sources || error_exit "Failed to change to Sources directory"

# Function to download a file with error checking
download_file() {
    local base_url="$1"
    local pkg="$2"
    local description="$3"

    echo "Downloading $description: $pkg..."
    if [ ! -f "$pkg" ]; then
        if ! fetch -o "$pkg" "${base_url}${pkg}"; then
            error_exit "Failed to download $description: ${base_url}${pkg}"
        fi
        # Verify that the file was downloaded successfully
        if [ ! -f "$pkg" ]; then
            error_exit "Download appeared successful but file not found: $pkg"
        fi
        echo "Successfully downloaded $description: $pkg"
    else
        echo "File already exists, skipping download: $pkg"
    fi
}

download_file "$ftpGnu/bash/" "bash-5.2.21.tar.gz" "Bash"
download_file "$ftpGnu/sed/" "sed-4.9.tar.xz" "Sed"

download_file "$ftpGnu/coreutils/" "coreutils-9.1.tar.xz" "Coreutils"

download_file "https://github.com/tukaani-project/xz/releases/download/v5.4.0/" "xz-5.4.0.tar.gz" "XZ Utils"
download_file "https://www.sudo.ws/dist/src/sudo/" "sudo-1.9.14p3.tar.gz" "Sudo"
download_file "https://www.python.org/ftp/python/3.11.0/" "Python-3.11.0.tgz" "Python"
download_file "$ftpGnu/findutils/" "findutils-4.9.0.tar.xz" "Findutils"
download_file "$ftpGnu/diffutils/" "diffutils-3.9.tar.xz" "Diffutils"

download_file "$ftpGnu/grep/" "grep-3.11.tar.xz" "Grep"
download_file "$ftpGnu/wget/" "wget-1.21.4.tar.gz" "Wget"
download_file "$ftpGnu/automake/" "automake-1.16.5.tar.xz" "Automake"
download_file "https://www.cpan.org/src/5.0/" "perl-5.36.0.tar.gz" "Perl"
download_file "$ftpGnu/autoconf/" "autoconf-2.71.tar.xz" "Autoconf"
download_file "$ftpGnu/m4/" "m4-1.4.19.tar.xz" "M4"
download_file "$ftpGnu/libtool/" "libtool-2.4.7.tar.xz" "Libtool"
download_file "https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.42/" "pcre2-10.42.tar.bz2" "PCRE2"

download_file "https://github.com/gobolinux/Scripts/releases/download/016.02/" "Scripts-016.02.tar.gz" "GoboLinux Scripts"
download_file "https://github.com/gobolinux/Compile/releases/download/016/" "Compile-016.tar.gz" "GoboLinux Compile"
download_file "$ftpGnu/make/" "make-4.4.1.tar.gz" "Make"
download_file "https://www.openssl.org/source/" "openssl-3.1.4.tar.gz" "OpenSSL"

# Additional utilities for desktop environment
download_file "https://download.kde.org/stable/frameworks/5.111/" "extra-cmake-modules-5.111.0.tar.xz" "Extra CMake Modules"
download_file "https://download.kde.org/stable/frameworks/5.111/" "kcoreaddons-5.111.0.tar.xz" "KCoreAddons"
download_file "https://download.kde.org/stable/frameworks/5.111/" "kconfig-5.111.0.tar.xz" "KConfig"
download_file "https://download.kde.org/stable/frameworks/5.111/" "kdbusaddons-5.111.0.tar.xz" "KDBusAddons"

download_file "https://download.kde.org/stable/frameworks/5.111/" "ki18n-5.111.0.tar.xz" "KI18n"
download_file "https://download.kde.org/stable/frameworks/5.111/" "kwidgetsaddons-5.111.0.tar.xz" "KWidgetsAddons"
download_file "https://download.kde.org/stable/frameworks/5.111/" "kwindowsystem-5.111.0.tar.xz" "KWindowSystem"
download_file "https://download.kde.org/stable/plasma/6.0.0/" "plasma-workspace-6.0.0.tar.xz" "Plasma Workspace"

download_file "https://download.kde.org/stable/plasma/6.0.0/" "plasma-desktop-6.0.0.tar.xz" "Plasma Desktop"

# X.Org components
download_file "https://www.x.org/releases/individual/xserver/" "xorg-server-21.1.13.tar.xz" "X.Org Server"
download_file "https://www.x.org/releases/individual/lib/" "libX11-1.8.9.tar.xz" "LibX11"
download_file "https://www.x.org/releases/individual/lib/" "libxcb-1.15.tar.xz" "LibXCB"
download_file "https://www.x.org/releases/individual/lib/" "libXext-1.3.6.tar.xz" "LibXext"
download_file "https://www.x.org/releases/individual/lib/" "libXrandr-1.5.4.tar.xz" "LibXrandr"
download_file "https://www.x.org/releases/individual/lib/" "libXrender-0.9.11.tar.xz" "LibXrender"

download_file "https://www.x.org/releases/individual/lib/" "libXfixes-6.0.1.tar.xz" "LibXfixes"

download_file "https://www.x.org/releases/individual/lib/" "libXcursor-1.2.2.tar.xz" "LibXcursor"
download_file "https://www.x.org/releases/individual/lib/" "libXi-1.8.tar.xz" "LibXi"
download_file "https://www.x.org/releases/individual/lib/" "libXinerama-1.1.5.tar.xz" "LibXinerama"
download_file "https://www.x.org/releases/individual/lib/" "libXScrnSaver-1.2.4.tar.xz" "LibXScrnSaver"
download_file "https://www.x.org/releases/individual/lib/" "libXtst-1.2.5.tar.xz" "LibXtst"
download_file "https://www.x.org/releases/individual/lib/" "libXcomposite-0.4.6.tar.xz" "LibXcomposite"
download_file "https://www.x.org/releases/individual/lib/" "libXdamage-1.1.6.tar.xz" "LibXdamage"
download_file "https://www.x.org/releases/individual/lib/" "libXxf86vm-1.1.5.tar.xz" "LibXxf86vm"

download_file "https://www.x.org/releases/individual/lib/" "libXmu-1.1.4.tar.xz" "LibXmu"
download_file "https://www.x.org/releases/individual/lib/" "libXpm-3.5.16.tar.xz" "LibXpm"
download_file "https://www.x.org/releases/individual/lib/" "libXft-2.3.8.tar.xz" "LibXft"
download_file "https://www.x.org/releases/individual/lib/" "libXaw-1.0.16.tar.xz" "LibXaw"

download_file "https://www.x.org/releases/individual/app/" "xinit-1.4.2.tar.xz" "Xinit"
download_file "https://www.x.org/releases/individual/app/" "xrandr-1.5.2.tar.xz" "Xrandr"
download_file "https://www.x.org/releases/individual/app/" "xset-1.2.5.tar.xz" "Xset"
download_file "https://www.x.org/releases/individual/app/" "xinput-1.6.3.tar.xz" "Xinput"

download_file "https://www.x.org/releases/individual/app/" "xprop-1.2.6.tar.xz" "Xprop"
download_file "https://www.x.org/releases/individual/app/" "xwininfo-1.1.6.tar.xz" "Xwininfo"
download_file "https://www.x.org/releases/individual/app/" "xhost-1.0.9.tar.xz" "Xhost"
download_file "https://www.x.org/releases/individual/app/" "xauth-1.1.3.tar.xz" "Xauth"

# Additional libraries for KDE
download_file "https://download.kde.org/stable/frameworks/5.111/" "kauth-5.111.0.tar.xz" "KAuth"
download_file "https://download.kde.org/stable/frameworks/5.111/" "kcrash-5.111.0.tar.xz" "KCrash"
download_file "https://download.kde.org/stable/frameworks/5.111/" "kguiaddons-5.111.0.tar.xz" "KGuiAddons"
download_file "https://download.kde.org/stable/frameworks/5.111/" "kcodecs-5.111.0.tar.xz" "KCodecs"
download_file "https://download.kde.org/stable/frameworks/5.111/" "kholidays-5.111.0.tar.xz" "KHolidays"
download_file "https://download.kde.org/stable/frameworks/5.111/" "kitemmodels-5.111.0.tar.xz" "KItemModels"
download_file "https://download.kde.org/stable/frameworks/5.111/" "kitemviews-5.111.0.tar.xz" "KItemViews"
download_file "https://download.kde.org/stable/frameworks/5.111/" "ktextwidgets-5.111.0.tar.xz" "KTextWidgets"
download_file "https://download.kde.org/stable/frameworks/5.111/" "kxmlgui-5.111.0.tar.xz" "KXMLGUI"

download_file "https://download.kde.org/stable/frameworks/5.111/" "knotifications-5.111.0.tar.xz" "KNotifications"
download_file "https://download.kde.org/stable/frameworks/5.111/" "knotifyconfig-5.111.0.tar.xz" "KNotifyConfig"
download_file "https://download.kde.org/stable/frameworks/5.111/" "kservice-5.111.0.tar.xz" "KService"
download_file "https://download.kde.org/stable/frameworks/5.111/" "kiconthemes-5.111.0.tar.xz" "KIconThemes"
download_file "https://download.kde.org/stable/frameworks/5.111/" "kjobwidgets-5.111.0.tar.xz" "KJobWidgets"
download_file "https://download.kde.org/stable/frameworks/5.111/" "kdbusinterface-5.111.0.tar.xz" "KDBusInterface"
download_file "https://download.kde.org/stable/frameworks/5.111/" "kcmutils-5.111.0.tar.xz" "KCmUtils"
download_file "https://download.kde.org/stable/frameworks/5.111/" "kdeclarative-5.111.0.tar.xz" "KDeclarative"
download_file "https://download.kde.org/stable/frameworks/5.111/" "kded-5.111.0.tar.xz" "KDED"

download_file "https://download.kde.org/stable/frameworks/5.111/" "kdesu-5.111.0.tar.xz" "KDEsu"
download_file "https://download.kde.org/stable/frameworks/5.111/" "kemoticons-5.111.0.tar.xz" "KEmoticons"
download_file "https://download.kde.org/stable/frameworks/5.111/" "kglobalaccel-5.111.0.tar.xz" "KGlobalAccel"
download_file "https://download.kde.org/stable/frameworks/5.111/" "khotkeys-5.111.0.tar.xz" "KHotKeys"
download_file "https://download.kde.org/stable/frameworks/5.111/" "kidletime-5.111.0.tar.xz" "KIdleTime"
download_file "https://download.kde.org/stable/frameworks/5.111/" "kimageformats-5.111.0.tar.xz" "KImageFormats"
download_file "https://download.kde.org/stable/frameworks/5.111/" "kinfocenter-5.111.0.tar.xz" "KInfoCenter"
download_file "https://download.kde.org/stable/frameworks/5.111/" "kinit-5.111.0.tar.xz" "KInit"
download_file "https://download.kde.org/stable/frameworks/5.111/" "kio-5.111.0.tar.xz" "KIO"

download_file "https://download.kde.org/stable/frameworks/5.111/" "kirigami-5.111.0.tar.xz" "Kirigami"
download_file "https://download.kde.org/stable/frameworks/5.111/" "knewstuff-5.111.0.tar.xz" "KNewStuff"
download_file "https://download.kde.org/stable/frameworks/5.111/" "kpackage-5.111.0.tar.xz" "KPackage"
download_file "https://download.kde.org/stable/frameworks/5.111/" "kparts-5.111.0.tar.xz" "KParts"
download_file "https://download.kde.org/stable/frameworks/5.111/" "kpeople-5.111.0.tar.xz" "KPeople"
download_file "https://download.kde.org/stable/frameworks/5.111/" "krunner-5.111.0.tar.xz" "KRunner"
download_file "https://download.kde.org/stable/frameworks/5.111/" "kscreen-5.111.0.tar.xz" "KScreen"
download_file "https://download.kde.org/stable/frameworks/5.111/" "kscreenlocker-5.111.0.tar.xz" "KScreenLocker"
download_file "https://download.kde.org/stable/frameworks/5.111/" "ksysguard-5.111.0.tar.xz" "KSysGuard"

download_file "https://download.kde.org/stable/frameworks/5.111/" "ktexteditor-5.111.0.tar.xz" "KTextEditor"
download_file "https://download.kde.org/stable/frameworks/5.111/" "kwallet-5.111.0.tar.xz" "KWallet"
download_file "https://download.kde.org/stable/frameworks/5.111/" "kwayland-5.111.0.tar.xz" "KWayland"
download_file "https://download.kde.org/stable/frameworks/5.111/" "kwidgetsaddons-5.111.0.tar.xz" "KWidgetsAddons"
download_file "https://download.kde.org/stable/frameworks/5.111/" "kxmlgui-5.111.0.tar.xz" "KXMLGUI"
download_file "https://download.kde.org/stable/frameworks/5.111/" "plasma-framework-5.111.0.tar.xz" "Plasma Framework"

# Graphics libraries
download_file "https://gitlab.freedesktop.org/mesa/mesa/-/archive/" "mesa-23.3.6.tar.bz2" "Mesa 3D Graphics Library"
download_file "https://download.sourceforge.net/libpng/" "libpng-1.6.40.tar.xz" "LibPNG"
download_file "https://www.cairographics.org/releases/" "cairo-1.18.0.tar.xz" "Cairo Graphics"

download_file "https://download.gnome.org/sources/pango/1.50/" "pango-1.50.14.tar.xz" "Pango"
download_file "https://download.gnome.org/sources/glib/2.78/" "glib-2.78.3.tar.xz" "GLib"
download_file "https://download.gnome.org/sources/at-spi2-core/2.50/" "at-spi2-core-2.50.0.tar.xz" "AT-SPI2 Core"
download_file "https://download.gnome.org/sources/at-spi2-atk/2.38/" "at-spi2-atk-2.38.0.tar.xz" "AT-SPI2 ATK"
download_file "https://download.gnome.org/sources/atk/2.38/" "atk-2.38.0.tar.xz" "ATK"
download_file "https://download.gnome.org/sources/gdk-pixbuf/2.42/" "gdk-pixbuf-2.42.10.tar.xz" "GDK-Pixbuf"
download_file "https://download.gnome.org/sources/harfbuzz/8.3/" "harfbuzz-8.3.0.tar.xz" "HarfBuzz"
download_file "https://download.gnome.org/sources/freetype/2.13/" "freetype-2.13.2.tar.xz" "FreeType"
download_file "https://download.gnome.org/sources/fontconfig/2.14/" "fontconfig-2.14.2.tar.xz" "Fontconfig"

download_file "https://download.gnome.org/sources/libepoxy/1.5/" "libepoxy-1.5.10.tar.xz" "LibEpoxy"

# Audio libraries
download_file "https://www.freedesktop.org/software/pulseaudio/releases/" "pulseaudio-17.0.tar.xz" "PulseAudio"
download_file "https://github.com/alsa-project/alsa-lib/archive/" "v1.2.10.tar.gz" "ALSA Library"

# Multimedia libraries
download_file "https://github.com/FFmpeg/FFmpeg/releases/download/n6.0/" "ffmpeg-6.0.tar.xz" "FFmpeg"

# Window manager
download_file "https://github.com/KDE/kwin/releases/download/v5.27.10/" "kwin-5.27.10.tar.xz" "KWin"

# Display drivers and graphics utilities for FreeBSD
download_file "https://github.com/freebsd/drm-kmod/releases/download/drm-kmod-5.4.3/" "drm-kmod-5.4.3.tar.xz" "DRM KMOD"

# Mesa 3D graphics library with FreeBSD DRM support
download_file "https://gitlab.freedesktop.org/mesa/mesa/-/archive/mesa-23.3.6/" "mesa-23.3.6.tar.xz" "Mesa 3D with DRM support"

# SDDM display manager
download_file "https://github.com/sddm/sddm/releases/download/v0.20.0/" "sddm-0.20.0.tar.xz" "SDDM Display Manager"

# Additional graphics libraries
download_file "https://gitlab.freedesktop.org/wayland/wayland/-/archive/1.22.0/" "wayland-1.22.0.tar.xz" "Wayland"
download_file "https://gitlab.freedesktop.org/wayland/wayland-protocols/-/archive/1.33/" "wayland-protocols-1.33.tar.xz" "Wayland Protocols"

# Input device support
download_file "https://www.x.org/releases/individual/xdriver/" "xf86-input-libinput-1.3.0.tar.xz" "XF86 Input Libinput"

# Video drivers for FreeBSD
download_file "https://www.x.org/releases/individual/xdriver/" "xf86-video-vesa-2.5.0.tar.xz" "XF86 Video VESA"
download_file "https://www.x.org/releases/individual/xdriver/" "xf86-video-modesetting-0.11.0.tar.xz" "XF86 Video Modesetting"

# Console and terminal utilities
download_file "https://github.com/ConsoleKit/elogind/archive/v253.3/" "elogind-253.3.tar.xz" "ELogind"

# System utilities for live environment
download_file "https://github.com/util-linux/util-linux/releases/download/v2.39/" "util-linux-2.39.tar.xz" "Util Linux"

# Network utilities
download_file "https://github.com/sahlberg/libnfs/releases/download/libnfs-4.0.0/" "libnfs-4.0.0.tar.gz" "LibNFS"

# Additional display and graphics utilities
download_file "https://gitlab.freedesktop.org/drm/" "libdrm-2.4.120.tar.xz" "LibDRM"

# Graphics drivers for FreeBSD
download_file "https://www.x.org/releases/individual/xdriver/" "xf86-video-intel-2023.03.15.tar.xz" "XF86 Video Intel"
download_file "https://www.x.org/releases/individual/xdriver/" "xf86-video-amdgpu-23.0.0.tar.xz" "XF86 Video AMDGPU"
download_file "https://www.x.org/releases/individual/xdriver/" "xf86-video-radeon-19.1.0.tar.xz" "XF86 Video Radeon"

# Additional packages to be compiled with Compile (as per TODO)
download_file "https://www.openssl.org/source/" "openssl-3.1.4.tar.gz" "OpenSSL"

# Python is already downloaded earlier in the script, so we don't need to download it again

download_file "https://ftp.gnu.org/gnu/ncurses/" "ncurses-6.4.tar.gz" "Ncurses"
download_file "https://ftp.gnu.org/gnu/bash/" "bash-5.2.21.tar.gz" "Bash"

# Additional desktop utilities (that weren't already added)
download_file "https://ftp.gnu.org/gnu/gawk/" "gawk-5.2.1.tar.xz" "Gawk"
download_file "https://ftp.gnu.org/gnu/tar/" "tar-1.34.tar.xz" "Tar"
download_file "https://ftp.gnu.org/gnu/gzip/" "gzip-1.12.tar.xz" "Gzip"
download_file "https://ftp.gnu.org/gnu/bzip2/" "bzip2-1.0.8.tar.gz" "Bzip2"

# Note: Some packages are duplicated, so we'll just keep one instance of each
download_file "https://github.com/xz-mirror/xz/releases/download/v5.4.0/" "xz-5.4.0.tar.gz" "XZ Utils"

# Web browser components
download_file "https://archive.mozilla.org/pub/firefox/releases/115.0/source/" "firefox-115.0.source.tar.xz" "Firefox"

# Text editor
download_file "https://github.com/microsoft/vscode/archive/" "vscode-1.85.0.tar.gz" "VSCode"

# File manager
download_file "https://download.kde.org/stable/dolphin/" "dolphin-23.08.4.tar.xz" "Dolphin File Manager"

# Archive manager
download_file "https://download.kde.org/stable/ark/" "ark-23.08.4.tar.xz" "Ark Archive Manager"

# Audio player
download_file "https://github.com/atheme/audacious/releases/download/4.3/" "audacious-4.3.tar.bz2" "Audacious Audio Player"

# Image viewer
download_file "https://download.kde.org/stable/gwenview/" "gwenview-23.08.4.tar.xz" "Gwenview Image Viewer"

# Document viewer
download_file "https://download.kde.org/stable/okular/" "okular-23.08.4.tar.xz" "Okular Document Viewer"

# Terminal emulator
download_file "https://download.kde.org/stable/konsole/" "konsole-23.08.4.tar.xz" "Konsole Terminal"

# Text editor
download_file "https://download.kde.org/stable/kate/" "kate-23.08.4.tar.xz" "Kate Text Editor"

# Network management utilities
download_file "https://github.com/Distrotech/wpa_supplicant/archive/" "wpa_supplicant-2.10.tar.gz" "WPA Supplicant"

# NetworkManager (for GUI network management)
download_file "https://download.gnome.org/sources/NetworkManager/1.44/" "NetworkManager-1.44.0.tar.xz" "NetworkManager"

# DHCP client
download_file "https://ftp.isc.org/isc/dhcp/4.4.3-P1/" "dhcp-4.4.3-P1.tar.gz" "DHCP Client"

# Wireless tools
download_file "https://www.hpl.hp.com/personal/Jean_Tourrilhes/Linux/" "wireless_tools.29.tar.gz" "Wireless Tools"

# Network utilities
download_file "https://github.com/iputils/iputils/releases/download/20221102/" "iputils-20221102.tar.gz" "IP Utilities"

# Virtualization support packages
download_file "https://gitlab.freedesktop.org/mesa/mesa/-/archive/mesa-23.3.6/" "mesa-23.3.6.tar.xz" "Mesa 3D for Virtualization"

# VirtualBox guest additions components (for virtualization support)
# We'll include headers and libraries needed for virtualization
download_file "https://www.x.org/releases/individual/xserver/" "xorg-server-21.1.13.tar.xz" "X.Org Server for Virtualization"

# VirtualGL for 3D acceleration in virtual machines
download_file "https://github.com/VirtualGL/virtualgl/archive/" "VirtualGL-3.1.tar.gz" "VirtualGL"

# AlienVFS dependencies - Lua and related packages
download_file "https://www.lua.org/ftp/" "lua-5.4.6.tar.gz" "Lua"
download_file "https://luarocks.org/releases/" "luarocks-3.9.2.tar.gz" "LuaRocks"

# FUSE for FreeBSD
download_file "https://github.com/libfuse/libfuse/releases/download/fuse-3.16.2/" "fuse-3.16.2.tar.xz" "FUSE"

# Lua libraries needed by AlienVFS
download_file "https://github.com/gvvaughan/luaposix/archive/v36.1/" "luaposix-36.1.tar.gz" "LuaPosix"
download_file "https://github.com/kengonakajima/luafun/archive/v0.2/" "luafun-0.2.tar.gz" "LuaFun"
download_file "https://github.com/kikito/inspect.lua/archive/" "inspect.lua-3.1.3.tar.gz" "Inspect.lua"
download_file "https://github.com/hoelzro/lua-llthreads2/archive/" "lua-llthreads2-1.0.0.tar.gz" "Lua Llthreads2"
download_file "https://github.com/luvit/luv/archive/" "luv-1.44.2.tar.gz" "Luv"

# Additional Lua dependencies for AlienVFS
download_file "https://github.com/gilzoide/lua-inotify/archive/" "lua-inotify-1.0.tar.gz" "Lua Inotify"
download_file "https://github.com/kikito/flu/archive/" "flu-1.2.tar.gz" "Flu"
download_file "https://github.com/grafi-tt/lunajson/archive/" "lunajson-1.3.tar.gz" "Lunajson"

# Copy AlienVFS source to resources
cp -r /home/nohearth/AlienVFS ${ROOTDIR}/Files/Compile/Sources/AlienVFS

# Rust development tools
download_file "https://static.rust-lang.org/dist/" "rust-1.75.0-x86_64-unknown-freebsd.tar.gz" "Rust"
download_file "https://github.com/rust-lang/rustup/archive/" "rustup-1.26.0.tar.gz" "Rustup"

# Code editor - VS Code alternative for FreeBSD
# Note: This is a duplicate, already added earlier
# download_file "https://github.com/microsoft/vscode/archive/" "vscode-1.85.0.tar.gz" "VSCode"

# Alternative: Code-Server for web-based VS Code
download_file "https://github.com/coder/code-server/releases/download/v4.21.1/" "code-server-4.21.1.tar.gz" "Code Server"

# Additional Rust dependencies
download_file "https://github.com/rust-lang/cargo/archive/" "cargo-0.78.0.tar.gz" "Cargo"

# GoboHide - filesystem hiding utility for GoboLinux
download_file "https://github.com/gobolinux/GoboHide/releases/download/1.3/" "GoboHide-1.3.tar.gz" "GoboHide"

# Nano editor - lightweight text editor as backup
download_file "https://www.nano-editor.org/dist/v7/" "nano-7.2.tar.xz" "Nano Editor"

# SteamCMD for FreeBSD
download_file "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" "steamcmd_linux.tar.gz" "SteamCMD"

# Wine for FreeBSD (using compatibility layer)
download_file "https://github.com/mstefanro/wine-freebsd/releases/download/wine-freebsd-10.0/wine-freebsd-10.0.tar.xz" "wine-freebsd-10.0.tar.xz" "Wine FreeBSD"

# GPart - FreeBSD partitioning tool (gpart is part of base system, but we can include additional utilities)
# Note: gpart is already part of FreeBSD base system, so we don't need to download it separately

# GoboLinux Installer
download_file "https://github.com/gobolinux/Installer/releases/download/016/" "Installer-016.tar.gz" "GoboLinux Installer"

# Additional utilities as mentioned in TODO
# System monitoring tools
download_file "https://github.com/aristocratos/btop/archive/refs/tags/v1.2.13.tar.gz" "btop-1.2.13.tar.gz" "Btop System Monitor"
download_file "https://github.com/hishamhm/htop/archive/refs/tags/3.2.2.tar.gz" "htop-3.2.2.tar.gz" "Htop System Monitor"

# File management utilities
download_file "https://github.com/ventoy/Ventoy/releases/download/v1.0.95/ventoy-1.0.95-linux.tar.gz" "ventoy-1.0.95-linux.tar.gz" "Ventoy Boot Manager"
download_file "https://ftp.gnu.org/gnu/less/" "less-633.tar.gz" "Less Pager"

# Compression utilities
download_file "https://github.com/madler/zlib/releases/download/v1.3/zlib-1.3.tar.gz" "zlib-1.3.tar.gz" "Zlib Compression Library"
download_file "https://github.com/lz4/lz4/archive/v1.9.4.tar.gz" "lz4-1.9.4.tar.gz" "LZ4 Compression"
download_file "https://github.com/facebook/zstd/releases/download/v1.5.2/zstd-1.5.2.tar.gz" "zstd-1.5.2.tar.gz" "Zstandard Compression"

# Network utilities
download_file "https://curl.se/download/curl-8.4.0.tar.gz" "curl-8.4.0.tar.gz" "Curl"
download_file "https://github.com/git/git/archive/refs/tags/v2.42.0.tar.gz" "git-2.42.0.tar.gz" "Git"
download_file "https://github.com/tmate-io/tmate/archive/refs/tags/2.4.0.tar.gz" "tmate-2.4.0.tar.gz" "Tmate Terminal Multiplexer"

# Security utilities
download_file "https://github.com/FiloSottile/age/releases/download/v1.1.0/age-1.1.0.tar.gz" "age-1.1.0.tar.gz" "Age File Encryption"

# Development utilities
download_file "https://github.com/git-lfs/git-lfs/releases/download/v3.4.0/git-lfs-3.4.0.tar.gz" "git-lfs-3.4.0.tar.gz" "Git LFS"
download_file "https://github.com/tj/git-extras/archive/refs/tags/7.1.0.tar.gz" "git-extras-7.1.0.tar.gz" "Git Extras"

exit 0
