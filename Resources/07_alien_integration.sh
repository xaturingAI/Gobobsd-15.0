#!/bin/sh

umask 022

if [ ! -f "${bootstrapScriptsDir}/07_alien_integration.sh" ]; then
  echo "Please execute $0 from its directory"
  exit 201
fi

. ./bootstrap_env.inc

echo "Setting up AlienVFS integration for GoboBSD..."

# Create necessary AlienVFS directories
mkdir -p ${ROOT}/System/Aliens
mkdir -p ${ROOT}/System/Aliens-bindmount
mkdir -p ${ROOT}/System/Settings

# Create the Alien command script
cat > ${ROOT}/System/Setup/setup_alien_command.sh << "EOF"
#!/bin/sh
# Script to create the Alien command for GoboBSD

# Create Alien command that interfaces with AlienVFS
cat > /System/Links/Executables/Alien << "ALIENSCRIPT"
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
                pip3 install "$PKG_NAME" || pip install "$PKG_NAME"
                ;;
            CPAN)
                cpan "$PKG_NAME"
                ;;
            LuaRocks)
                luarocks install "$PKG_NAME"
                ;;
            RubyGems)
                gem install "$PKG_NAME"
                ;;
            Cargo)
                cargo install "$PKG_NAME"
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
                pip3 show "$PKG_NAME" 2>/dev/null | grep Version || echo "unknown"
                ;;
            CPAN)
                perl -e "use $PKG_NAME; print \$${PKG_NAME}::VERSION || 'unknown';"
                ;;
            LuaRocks)
                luarocks list | grep "$PKG_NAME" || echo "unknown"
                ;;
            RubyGems)
                gem list "^$PKG_NAME\$" | head -n1 | awk '{print $2}' | tr -d '(),'
                ;;
            Cargo)
                cargo search "$PKG_NAME" --limit 1 | head -n1 | awk '{print $1}' | sed 's/".*://' || echo "unknown"
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
                pip3 show "$PKG_NAME" >/dev/null 2>&1
                ;;
            CPAN)
                perl -e "use $PKG_NAME" >/dev/null 2>&1
                ;;
            LuaRocks)
                luarocks show "$PKG_NAME" >/dev/null 2>&1
                ;;
            RubyGems)
                gem list "^$PKG_NAME\$" >/dev/null 2>&1
                ;;
            Cargo)
                cargo install --list | grep "$PKG_NAME" >/dev/null 2>&1
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

chmod +x /System/Links/Executables/Alien

# Create a default Aliens package list
cat > /System/Settings/Aliens-Packages-List << "ALIENLIST"
# Default Alien packages for GoboBSD
# Format: PackageManager:PackageName
PIP3:requests
PIP3:numpy
PIP3:beautifulsoup4
LuaRocks:lgi
LuaRocks:luafilesystem
CPAN:JSON
CPAN:XML::Parser
Cargo:cargo-update
ALIENLIST

echo "Alien command created successfully."
EOF

chmod +x ${ROOT}/System/Setup/setup_alien_command.sh

# Create AlienVFS mount setup script
cat > ${ROOT}/System/Setup/setup_alienvfs_mount.sh << "EOF"
#!/bin/sh
# Script to set up AlienVFS mount points

# Create mount points for AlienVFS
mkdir -p /System/Aliens
mkdir -p /System/Aliens-bindmount

# Create a script to mount AlienVFS when needed
cat > /System/Setup/mount_alienvfs.sh << "MOUNTSCRIPT"
#!/bin/sh
# Mount script for AlienVFS

# Mount the base Aliens directory
if [ ! -d /System/Aliens-bindmount ]; then
    mkdir -p /System/Aliens-bindmount
fi

# If AlienVFS is available, mount it
if [ -x /System/Links/Executables/AlienVFS ]; then
    # Start AlienVFS to mount programming language packages
    # This would typically be run as a service
    echo "AlienVFS is available at /System/Links/Executables/AlienVFS"
    echo "Run: AlienVFS /Mount/Aliens to mount the virtual filesystem"
else
    # Fallback: bind mount the base directory
    mount -o bind /System/Aliens /System/Aliens-bindmount 2>/dev/null || true
fi
MOUNTSCRIPT

chmod +x /System/Setup/mount_alienvfs.sh

echo "AlienVFS mount setup completed."
EOF

chmod +x ${ROOT}/System/Setup/setup_alienvfs_mount.sh

# Create a script to run at the end of chroot setup
cat > ${ROOT}/System/Setup/finalize_alien_integration.sh << "EOF"
#!/bin/sh
# Finalize AlienVFS integration

# Run Alien command setup
/System/Setup/setup_alien_command.sh

# Run AlienVFS mount setup
/System/Setup/setup_alienvfs_mount.sh

# Create a sample mount point
mkdir -p /Mount/Aliens

# Add Alien command to user profiles
echo 'export PATH="$PATH:/System/Links/Executables"' >> /Users/live/.profile

# Create a welcome message about Alien support
cat > /Users/live/Alien_Usage.txt << "WELCOME"
Welcome to GoboBSD with Alien package support!

Alien is a command-line tool to work with external package managers:
- Alien --install PIP3:requests          # Install Python package
- Alien --install LuaRocks:luafilesystem # Install Lua package
- Alien --install CPAN:JSON              # Install Perl package
- Alien --install Cargo:ripgrep          # Install Rust package

AlienVFS provides a virtual filesystem for these packages:
- Run: AlienVFS /Mount/Aliens            # Mount the virtual filesystem
- Aliens will appear under /Mount/Aliens

Supported package managers:
- PIP3 (Python)
- LuaRocks (Lua) 
- CPAN (Perl)
- RubyGems (Ruby)
- Cargo (Rust)
WELCOME

# Install default Alien packages during ISO build
echo "Installing default Alien packages..."

# Create a comprehensive list of packages to install during ISO build
cat > /tmp/alien_packages_iso_build.txt << "PACKAGELIST"
# Python packages
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
PIP3:charset-normalizer
PIP3:idna

# Lua packages
LuaRocks:lgi
LuaRocks:luafilesystem
LuaRocks:luaposix
LuaRocks:lunajson
LuaRocks:luautf8
LuaRocks:penlight

# Perl packages
CPAN:JSON
CPAN:XML::Parser
CPAN:Locale::gettext
CPAN:LWP::UserAgent
CPAN:HTTP::Tiny
CPAN:URI

# Ruby packages
RubyGems:bundler
RubyGems:nokogiri
RubyGems:json

# Rust packages
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
PACKAGELIST

# Install each package from the list
while IFS= read -r package; do
    if [ -n "$package" ] && [ "${package#'#'}" = "$package" ]; then  # Skip comments
        echo "Installing Alien package: $package"
        # Attempt to install the package using the appropriate package manager
        case "$package" in
            PIP3:*|PIP:*)
                pkg_name=$(echo "$package" | cut -d: -f2-)
                if command -v pip3 >/dev/null 2>&1; then
                    echo "Using pip3 to install $pkg_name"
                    pip3 install --user "$pkg_name" 2>/dev/null || echo "Failed to install $package via pip3"
                elif command -v pip >/dev/null 2>&1; then
                    echo "Using pip to install $pkg_name"
                    pip install --user "$pkg_name" 2>/dev/null || echo "Failed to install $package via pip"
                else
                    echo "No pip available to install $package"
                fi
                ;;
            LuaRocks:*)
                pkg_name=$(echo "$package" | cut -d: -f2-)
                if command -v luarocks >/dev/null 2>&1; then
                    echo "Using luarocks to install $pkg_name"
                    luarocks install "$pkg_name" 2>/dev/null || echo "Failed to install $package via luarocks"
                else
                    echo "No luarocks available to install $package"
                fi
                ;;
            CPAN:*)
                pkg_name=$(echo "$package" | cut -d: -f2-)
                if command -v perl >/dev/null 2>&1 && command -v cpan >/dev/null 2>&1; then
                    echo "Using CPAN to install $pkg_name"
                    cpan "$pkg_name" 2>/dev/null || echo "Failed to install $package via CPAN"
                else
                    echo "No CPAN available to install $package"
                fi
                ;;
            RubyGems:*)
                pkg_name=$(echo "$package" | cut -d: -f2-)
                if command -v gem >/dev/null 2>&1; then
                    echo "Using gem to install $pkg_name"
                    gem install "$pkg_name" 2>/dev/null || echo "Failed to install $package via gem"
                else
                    echo "No gem available to install $package"
                fi
                ;;
            Cargo:*)
                pkg_name=$(echo "$package" | cut -d: -f2-)
                if command -v cargo >/dev/null 2>&1; then
                    echo "Using cargo to install $pkg_name"
                    cargo install "$pkg_name" --locked 2>/dev/null || echo "Failed to install $package via cargo"
                else
                    echo "No cargo available to install $package"
                fi
                ;;
        esac
    fi
done < /tmp/alien_packages_iso_build.txt

rm -f /tmp/alien_packages_iso_build.txt

echo "AlienVFS integration completed!"
EOF

chmod +x ${ROOT}/System/Setup/finalize_alien_integration.sh

echo "AlienVFS integration setup completed."

exit 0