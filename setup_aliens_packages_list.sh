#!/bin/sh

# Create the Aliens-Packages-List file for GoboBSD
# This file will be used by the ISO building process to install Alien packages

# First check if the BuildLiveCD directory exists
if [ -d "/home/nohearth/Documents/BuildLiveCD" ]; then
    cat > /home/nohearth/Documents/BuildLiveCD/Data/Aliens-Packages-List << "EOF"
# Alien packages for GoboBSD
# Format: PackageManager:PackageName

# Essential Python packages
PIP3:requests
PIP3:beautifulsoup4
PIP3:numpy
PIP3:pandas
PIP3:matplotlib
PIP3:scipy
PIP3:flask
PIP3:urllib3
PIP3:certifi

# Essential Lua packages
LuaRocks:lgi
LuaRocks:luafilesystem
LuaRocks:luaposix
LuaRocks:lunajson

# Essential Perl packages
CPAN:JSON
CPAN:XML::Parser
CPAN:Locale::gettext

# Essential Ruby packages
RubyGems:bundler
RubyGems:nokogiri

# Essential Rust packages
Cargo:cargo-update
Cargo:ripgrep
Cargo:exa
Cargo:bat
Cargo:fd-find
Cargo:procs
EOF

    echo "Aliens-Packages-List created for GoboBSD in BuildLiveCD directory."
else
    echo "BuildLiveCD directory not found. Creating in current directory."
    cat > ./Aliens-Packages-List << "EOF"
# Alien packages for GoboBSD
# Format: PackageManager:PackageName

# Essential Python packages
PIP3:requests
PIP3:beautifulsoup4
PIP3:numpy
PIP3:pandas
PIP3:matplotlib
PIP3:scipy
PIP3:flask
PIP3:urllib3
PIP3:certifi

# Essential Lua packages
LuaRocks:lgi
LuaRocks:luafilesystem
LuaRocks:luaposix
LuaRocks:lunajson

# Essential Perl packages
CPAN:JSON
CPAN:XML::Parser
CPAN:Locale::gettext

# Essential Ruby packages
RubyGems:bundler
RubyGems:nokogiri

# Essential Rust packages
Cargo:cargo-update
Cargo:ripgrep
Cargo:exa
Cargo:bat
Cargo:fd-find
Cargo:procs
EOF

    echo "Aliens-Packages-List created for GoboBSD in current directory."
fi