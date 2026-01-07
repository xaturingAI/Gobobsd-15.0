#!/bin/sh

cd $(dirname $(which $0))
SCRIPTDIR=$(pwd)

. create_env.inc

ftpGnu=ftp://ftp.gnu.org/gnu

if [ ! -d ./Sources ]; then
  mkdir ./Sources || exit 1
fi

cd ./Sources

BASEURL="$ftpGnu/bash/"
PKG="bash-5.2.tar.gz"
if [ ! -f $PKG ]; then
  fetch ${BASEURL}${PKG} || exit 1
fi

BASEURL="$ftpGnu/sed/"
PKG="sed-4.9.tar.gz"
if [ ! -f $PKG ]; then
  fetch ${BASEURL}${PKG} || exit 1
fi

BASEURL="$ftpGnu/coreutils/"
PKG="coreutils-9.1.tar.xz"
if [ ! -f $PKG ]; then
  fetch ${BASEURL}${PKG} || exit 1
fi

BASEURL="https://tukaani.org/xz/"
PKG="xz-5.4.5.tar.gz"
if [ ! -f $PKG ]; then
  fetch ${BASEURL}${PKG} || exit 1
fi

BASEURL="https://www.sudo.ws/sudo/dist/"
PKG="sudo-1.9.15p1.tar.gz"
if [ ! -f $PKG ]; then
  fetch ${BASEURL}${PKG} || exit 1
fi

BASEURL="https://www.python.org/ftp/python/3.11.6/"
PKG="Python-3.11.6.tar.xz"
if [ ! -f $PKG ]; then
  fetch ${BASEURL}${PKG} || exit 1
fi

BASEURL="$ftpGnu/findutils/"
PKG="findutils-4.9.0.tar.xz"
if [ ! -f $PKG ]; then
  fetch ${BASEURL}${PKG} || exit 1
fi

BASEURL="$ftpGnu/diffutils/"
PKG="diffutils-3.10.tar.xz"
if [ ! -f $PKG ]; then
  fetch ${BASEURL}${PKG} || exit 1
fi

BASEURL="$ftpGnu/grep/"
PKG="grep-3.11.tar.xz"
if [ ! -f $PKG ]; then
  fetch ${BASEURL}${PKG} || exit 1
fi

BASEURL="$ftpGnu/wget/"
PKG="wget-1.21.4.tar.gz"
if [ ! -f $PKG ]; then
  fetch ${BASEURL}${PKG} || exit 1
fi

BASEURL="$ftpGnu/automake/"
PKG="automake-1.16.5.tar.xz"
if [ ! -f $PKG ]; then
  fetch ${BASEURL}${PKG} || exit 1
fi

BASEURL="https://www.cpan.org/src/5.0/"
PKG="perl-5.36.0.tar.gz"
if [ ! -f $PKG ]; then
  fetch ${BASEURL}${PKG} || exit 1
fi

BASEURL="$ftpGnu/autoconf/"
PKG="autoconf-2.71.tar.xz"
if [ ! -f $PKG ]; then
  fetch ${BASEURL}${PKG} || exit 1
fi

BASEURL="$ftpGnu/m4/"
PKG="m4-1.4.19.tar.xz"
if [ ! -f $PKG ]; then
  fetch ${BASEURL}${PKG} || exit 1
fi

BASEURL="$ftpGnu/libtool/"
PKG="libtool-2.4.7.tar.xz"
if [ ! -f $PKG ]; then
  fetch ${BASEURL}${PKG} || exit 1
fi

BASEURL="https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.42/"
PKG="pcre2-10.42.tar.bz2"
if [ ! -f $PKG ]; then
  fetch ${BASEURL}${PKG} || exit 1
fi

BASEURL="$ftpGnu/make/"
PKG="make-4.4.1.tar.gz"
if [ ! -f ${PKG} ]; then
  fetch -o ${PKG} ${BASEURL}${PKG} || exit 1
fi

BASEURL="https://www.openssl.org/source/"
PKG="openssl-3.1.4.tar.gz"
if [ ! -f ${PKG} ]; then
  fetch -o ${PKG} ${BASEURL}${PKG} || exit 1
fi

# X.org packages
XORGURL="https://www.x.org/releases/individual/proto/"
PKG="xorgproto-2024.1.tar.xz"
if [ ! -f $PKG ]; then
  fetch ${XORGURL}${PKG} || exit 1
fi

XORGURL="https://www.x.org/releases/individual/xserver/"
PKG="xorg-server-21.1.10.tar.gz"
if [ ! -f $PKG ]; then
  fetch ${XORGURL}${PKG} || exit 1
fi

XORGURL="https://www.x.org/releases/individual/lib/"
PKG="libX11-1.8.12.tar.xz"
if [ ! -f $PKG ]; then
  fetch ${XORGURL}${PKG} || exit 1
fi

XORGURL="https://www.x.org/releases/individual/lib/"
PKG="libxcb-1.15.tar.gz"
if [ ! -f $PKG ]; then
  fetch ${XORGURL}${PKG} || exit 1
fi

XORGURL="https://www.x.org/releases/individual/lib/"
PKG="libXext-1.3.6.tar.xz"
if [ ! -f $PKG ]; then
  fetch ${XORGURL}${PKG} || exit 1
fi

XORGURL="https://www.x.org/releases/individual/lib/"
PKG="libXrandr-1.5.3.tar.gz"
if [ ! -f $PKG ]; then
  fetch ${XORGURL}${PKG} || exit 1
fi

XORGURL="https://www.x.org/releases/individual/lib/"
PKG="libXi-1.8.tar.gz"
if [ ! -f $PKG ]; then
  fetch ${XORGURL}${PKG} || exit 1
fi

XORGURL="https://www.x.org/releases/individual/lib/"
PKG="libXrender-0.9.11.tar.gz"
if [ ! -f $PKG ]; then
  fetch ${XORGURL}${PKG} || exit 1
fi

XORGURL="https://www.x.org/releases/individual/lib/"
PKG="libXfixes-6.0.0.tar.gz"
if [ ! -f $PKG ]; then
  fetch ${XORGURL}${PKG} || exit 1
fi

XORGURL="https://www.x.org/releases/individual/lib/"
PKG="libXcursor-1.2.1.tar.gz"
if [ ! -f $PKG ]; then
  fetch ${XORGURL}${PKG} || exit 1
fi

XORGURL="https://www.x.org/releases/individual/lib/"
PKG="libXdamage-1.1.5.tar.gz"
if [ ! -f $PKG ]; then
  fetch ${XORGURL}${PKG} || exit 1
fi

XORGURL="https://www.x.org/releases/individual/lib/"
PKG="libXcomposite-0.4.5.tar.gz"
if [ ! -f $PKG ]; then
  fetch ${XORGURL}${PKG} || exit 1
fi

XORGURL="https://www.x.org/releases/individual/lib/"
PKG="libXtst-1.2.4.tar.gz"
if [ ! -f $PKG ]; then
  fetch ${XORGURL}${PKG} || exit 1
fi

XORGURL="https://www.x.org/releases/individual/lib/"
PKG="libXinerama-1.1.5.tar.gz"
if [ ! -f $PKG ]; then
  fetch ${XORGURL}${PKG} || exit 1
fi

XORGURL="https://www.x.org/releases/individual/lib/"
PKG="libXft-2.3.6.tar.gz"
if [ ! -f $PKG ]; then
  fetch ${XORGURL}${PKG} || exit 1
fi

XORGURL="https://www.x.org/releases/individual/lib/"
PKG="libXScrnSaver-1.2.5.tar.xz"
if [ ! -f $PKG ]; then
  fetch ${XORGURL}${PKG} || exit 1
fi

XORGURL="https://www.x.org/releases/individual/app/"
PKG="xinit-1.4.2.tar.gz"
if [ ! -f $PKG ]; then
  fetch ${XORGURL}${PKG} || exit 1
fi

XORGURL="https://www.x.org/releases/individual/app/"
PKG="xinput-1.6.3.tar.gz"
if [ ! -f $PKG ]; then
  fetch ${XORGURL}${PKG} || exit 1
fi

XORGURL="https://www.x.org/releases/individual/app/"
PKG="xrandr-1.5.2.tar.gz"
if [ ! -f $PKG ]; then
  fetch ${XORGURL}${PKG} || exit 1
fi

# Additional X.org packages based on dependencies
XORGURL="https://www.x.org/releases/individual/lib/"
PKG="libSM-1.2.4.tar.xz"
if [ ! -f $PKG ]; then
  fetch ${XORGURL}${PKG} || exit 1
fi

XORGURL="https://www.x.org/releases/individual/lib/"
PKG="libICE-1.1.1.tar.xz"
if [ ! -f $PKG ]; then
  fetch ${XORGURL}${PKG} || exit 1
fi

XORGURL="https://www.x.org/releases/individual/lib/"
PKG="libXt-1.3.0.tar.xz"
if [ ! -f $PKG ]; then
  fetch ${XORGURL}${PKG} || exit 1
fi

XORGURL="https://www.x.org/releases/individual/lib/"
PKG="libXfont2-2.0.6.tar.xz"
if [ ! -f $PKG ]; then
  fetch ${XORGURL}${PKG} || exit 1
fi

XORGURL="https://www.x.org/releases/individual/lib/"
PKG="libxkbfile-1.1.3.tar.xz"
if [ ! -f $PKG ]; then
  fetch ${XORGURL}${PKG} || exit 1
fi

XORGURL="https://www.x.org/releases/individual/lib/"
PKG="libfontenc-1.1.8.tar.xz"
if [ ! -f $PKG ]; then
  fetch ${XORGURL}${PKG} || exit 1
fi

XORGURL="https://www.x.org/releases/individual/lib/"
PKG="libXxf86vm-1.1.6.tar.xz"
if [ ! -f $PKG ]; then
  fetch ${XORGURL}${PKG} || exit 1
fi

XORGURL="https://www.x.org/releases/individual/lib/"
PKG="libXxf86dga-1.1.6.tar.xz"
if [ ! -f $PKG ]; then
  fetch ${XORGURL}${PKG} || exit 1
fi

XORGURL="https://www.x.org/releases/individual/lib/"
PKG="libXv-1.0.13.tar.xz"
if [ ! -f $PKG ]; then
  fetch ${XORGURL}${PKG} || exit 1
fi

XORGURL="https://www.x.org/releases/individual/lib/"
PKG="libXvMC-1.0.13.tar.xz"
if [ ! -f $PKG ]; then
  fetch ${XORGURL}${PKG} || exit 1
fi

XORGURL="https://www.x.org/releases/individual/lib/"
PKG="libXres-1.2.2.tar.xz"
if [ ! -f $PKG ]; then
  fetch ${XORGURL}${PKG} || exit 1
fi

XORGURL="https://www.x.org/releases/individual/lib/"
PKG="libFS-1.0.9.tar.xz"
if [ ! -f $PKG ]; then
  fetch ${XORGURL}${PKG} || exit 1
fi

XORGURL="https://www.x.org/releases/individual/lib/"
PKG="xtrans-1.6.0.tar.xz"
if [ ! -f $PKG ]; then
  fetch ${XORGURL}${PKG} || exit 1
fi

XORGURL="https://www.x.org/releases/individual/lib/"
PKG="pixman-0.43.4.tar.gz"
if [ ! -f $PKG ]; then
  fetch ${XORGURL}${PKG} || exit 1
fi

XORGURL="https://www.x.org/releases/individual/app/"
PKG="xkbcomp-1.4.6.tar.xz"
if [ ! -f $PKG ]; then
  fetch ${XORGURL}${PKG} || exit 1
fi

XORGURL="https://www.x.org/releases/individual/data/xkeyboard-config/"
PKG="xkeyboard-config-2.41.tar.xz"
if [ ! -f $PKG ]; then
  fetch ${XORGURL}${PKG} || exit 1
fi

XORGURL="https://gitlab.freedesktop.org/xorg/lib/libxshmfence/-/releases/"
# Note: libxshmfence doesn't follow standard naming, using GitHub release
XORGURL="https://www.x.org/releases/individual/lib/"
PKG="libxshmfence-1.3.2.tar.xz"
if [ ! -f $PKG ]; then
  fetch ${XORGURL}${PKG} || exit 1
fi

XORGURL="https://www.x.org/releases/individual/lib/"
PKG="libxcvt-0.1.3.tar.xz"
if [ ! -f $PKG ]; then
  fetch ${XORGURL}${PKG} || exit 1
fi

XORGURL="https://www.x.org/releases/individual/lib/"
PKG="libpciaccess-0.18.1.tar.xz"
if [ ! -f $PKG ]; then
  fetch ${XORGURL}${PKG} || exit 1
fi

DRMURL="https://dri.freedesktop.org/libdrm/"
PKG="libdrm-2.4.123.tar.xz"
if [ ! -f $PKG ]; then
  fetch ${DRMURL}${PKG} || exit 1
fi

GNOMEURL="https://download.gnome.org/sources/libepoxy/1.5/"
PKG="libepoxy-1.5.10.tar.xz"
if [ ! -f $PKG ]; then
  fetch ${GNOMEURL}${PKG} || exit 1
fi

# Mesa libraries for graphics support
MESAURL="https://mesa.freedesktop.org/archive/"
PKG="mesa-24.1.7.tar.xz"
if [ ! -f $PKG ]; then
  fetch ${MESAURL}${PKG} || exit 1
fi

# KDE Plasma 6 packages
KDEURL="https://download.kde.org/stable/plasma/6.4.5/"
PKG="plasma-desktop-6.4.5.tar.xz"
if [ ! -f $PKG ]; then
  fetch ${KDEURL}${PKG} || exit 1
fi

PKG="libplasma-6.4.5.tar.xz"
if [ ! -f $PKG ]; then
  fetch ${KDEURL}${PKG} || exit 1
fi

PKG="plasma-workspace-6.4.5.tar.xz"
if [ ! -f $PKG ]; then
  fetch ${KDEURL}${PKG} || exit 1
fi

PKG="kdeplasma-addons-6.4.5.tar.xz"
if [ ! -f $PKG ]; then
  fetch ${KDEURL}${PKG} || exit 1
fi

PKG="plasma-activities-6.4.5.tar.xz"
if [ ! -f $PKG ]; then
  fetch ${KDEURL}${PKG} || exit 1
fi

PKG="plasma-activities-stats-6.4.5.tar.xz"
if [ ! -f $PKG ]; then
  fetch ${KDEURL}${PKG} || exit 1
fi

PKG="kwin-6.4.5.tar.xz"
if [ ! -f $PKG ]; then
  fetch ${KDEURL}${PKG} || exit 1
fi

PKG="kscreenlocker-6.4.5.tar.xz"
if [ ! -f $PKG ]; then
  fetch ${KDEURL}${PKG} || exit 1
fi

PKG="kscreen-6.4.5.tar.xz"
if [ ! -f $PKG ]; then
  fetch ${KDEURL}${PKG} || exit 1
fi

PKG="systemsettings-6.4.5.tar.xz"
if [ ! -f $PKG ]; then
  fetch ${KDEURL}${PKG} || exit 1
fi

PKG="kactivitymanagerd-6.4.5.tar.xz"
if [ ! -f $PKG ]; then
  fetch ${KDEURL}${PKG} || exit 1
fi

PKG="kdecoration-6.4.5.tar.xz"
if [ ! -f $PKG ]; then
  fetch ${KDEURL}${PKG} || exit 1
fi

PKG="breeze-6.4.5.tar.xz"
if [ ! -f $PKG ]; then
  fetch ${KDEURL}${PKG} || exit 1
fi

PKG="breeze-gtk-6.4.5.tar.xz"
if [ ! -f $PKG ]; then
  fetch ${KDEURL}${PKG} || exit 1
fi

PKG="kwayland-6.4.5.tar.xz"
if [ ! -f $PKG ]; then
  fetch ${KDEURL}${PKG} || exit 1
fi

PKG="powerdevil-6.4.5.tar.xz"
if [ ! -f $PKG ]; then
  fetch ${KDEURL}${PKG} || exit 1
fi

# KDE Dolphin file manager
PKG="dolphin-25.08.1.tar.xz"
if [ ! -f $PKG ]; then
  fetch ${KDEURL}${PKG} || exit 1
fi

# Wayland packages
WAYLANDURL="https://gitlab.freedesktop.org/seatd/seatd/-/releases/download/0.9.1/"
PKG="seatd-0.9.1.tar.xz"
if [ ! -f $PKG ]; then
  fetch ${WAYLANDURL}${PKG} || exit 1
fi

exit 0
