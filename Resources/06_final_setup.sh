#!/bin/sh

umask 022

if [ ! -f "${bootstrapScriptsDir}/06_final_setup.sh" ]; then
  echo "Please execute $0 from its directory"
  exit 201
fi

. ./bootstrap_env.inc

echo "Performing final system setup..."

# Run the system links setup script
if [ -x /System/Setup/setup_system_links.sh ]; then
    /System/Setup/setup_system_links.sh
fi

# Enable SDDM if it was compiled
if [ -d /Programs/SDDM ]; then
    if [ -x /System/Setup/enable_sddm.sh ]; then
        /System/Setup/enable_sddm.sh
    fi
fi

# Create basic user directories
mkdir -p /Users/root
mkdir -p /Users/live
mkdir -p /tmp
mkdir -p /var/tmp

# Set proper permissions
chmod 1777 /tmp /var/tmp

# Create basic profile files for users
cat > /Users/root/.profile << "EOF"
# GoboBSD root profile
export PATH="/bin:/sbin:/usr/bin:/usr/sbin:/Programs/Bootstrap/Current/bin:/System/Links/Executables"
export PS1="[\u@\h \W]# "
export EDITOR=/System/Links/Executables/vi
export PAGER=/System/Links/Executables/less

# GoboLinux specific paths
export PATH="/System/Links/Executables:$PATH"
export MANPATH="/System/Links/Manuals:$MANPATH"
export INFOPATH="/System/Links/Executables:$INFOPATH"
export PKG_CONFIG_PATH="/System/Links/Libraries/pkgconfig:$PKG_CONFIG_PATH"
export LD_LIBRARY_PATH="/System/Links/Libraries:$LD_LIBRARY_PATH"
EOF

# Add users to video group for graphics access
echo "Adding users to video group for graphics access..."
pw groupadd -g 44 video 2>/dev/null || pw groupmod video -g 44 2>/dev/null
pw groupmod video -m fibo 2>/dev/null
pw groupmod video -m root 2>/dev/null

# Create a script to run at the end of chroot setup
cat > ${ROOT}/System/Setup/finalize_chroot.sh << "EOF"
#!/bin/sh
# Finalize chroot setup

# Run the system links setup
/System/Setup/setup_system_links.sh

# Enable SDDM if available
if [ -x /System/Setup/enable_sddm.sh ]; then
    /System/Setup/enable_sddm.sh
fi

# Update the system
echo "GoboBSD FreeBSD System" > /System/Settings/OSName

# Set up basic environment
ln -sf /System/Links/Environment/Scripts /etc/profile.d/scripts.sh 2>/dev/null || true

# Make sure all programs are properly linked
if [ -d /Programs/Scripts/Current ]; then
    /Programs/Scripts/Current/bin/SymlinkProgram Scripts 2>/dev/null || true
fi

# Set up basic user environment
mkdir -p /Users/root/.config
mkdir -p /Users/live/.config

# Add users to video group for graphics access
pw groupadd -g 44 video 2>/dev/null || pw groupmod video -g 44 2>/dev/null
pw groupmod video -m live 2>/dev/null
pw groupmod video -m root 2>/dev/null

# Create xinitrc for KDE if needed
if [ ! -f /Users/live/.xinitrc ]; then
    cat > /Users/live/.xinitrc << "XINITRC"
#!/bin/sh
# Start D-Bus and KDE Plasma
exec dbus-launch --exit-with-session startplasma-x11
XINITRC
    chown live:users /Users/live/.xinitrc
    chmod +x /Users/live/.xinitrc
fi

# Install AlienVFS using LuaRocks
if [ -d /Programs/Lua ]; then
    echo "Installing AlienVFS..."
    cd /Files/Compile/Sources/AlienVFS
    if [ -f "rockspecs/alienvfs-scm-1.rockspec" ]; then
        # Try to install using luarocks
        if command -v luarocks >/dev/null 2>&1; then
            luarocks make rockspecs/alienvfs-scm-1.rockspec --tree=/Programs/AlienVFS/Current 2>/dev/null || echo "AlienVFS installation needs manual setup"
        fi
    fi

    # Create a basic AlienVFS installation if the above fails
    if [ ! -d /Programs/AlienVFS ]; then
        mkdir -p /Programs/AlienVFS/Current/bin
        mkdir -p /Programs/AlienVFS/Current/lib
        cp AlienVFS /Programs/AlienVFS/Current/bin/AlienVFS
        cp -r gobo /Programs/AlienVFS/Current/lib/

        # Create symlink for AlienVFS
        ln -sf /Programs/AlienVFS/Current/bin/AlienVFS /System/Links/Executables/AlienVFS 2>/dev/null || true
    fi
fi

# Install Rust and set up development environment
if [ -d /Files/Compile/Sources/rust-* ]; then
    echo "Setting up Rust development environment..."

    # Find the rust directory
    for rust_dir in /Files/Compile/Sources/rust-*; do
        if [ -d "$rust_dir" ]; then
            cd "$rust_dir"
            break
        fi
    done

    # Install Rust using the installer if available
    if [ -f "install.sh" ]; then
        # Configure for GoboLinux
        ./install.sh --prefix=/Programs/Rust/Current --disable-ldconfig
    else
        # If no installer, create basic structure
        mkdir -p /Programs/Rust/Current/bin
        mkdir -p /Programs/Rust/Current/lib

        # Find and copy rust binaries if they exist
        find . -name "rustc" -type f -exec cp {} /Programs/Rust/Current/bin/ \; 2>/dev/null || true
        find . -name "cargo" -type f -exec cp {} /Programs/Rust/Current/bin/ \; 2>/dev/null || true
    fi

    # Create symlinks for Rust tools
    ln -sf /Programs/Rust/Current/bin/rustc /System/Links/Executables/rustc 2>/dev/null || true
    ln -sf /Programs/Rust/Current/bin/cargo /System/Links/Executables/cargo 2>/dev/null || true
    ln -sf /Programs/Rust/Current/bin/rustup /System/Links/Executables/rustup 2>/dev/null || true

    # Set up rustup if available
    if command -v rustup >/dev/null 2>&1; then
        # Install nightly toolchain
        rustup toolchain install nightly

        # Set up cargo configuration
        mkdir -p /Users/live/.cargo
        cat > /Users/live/.cargo/config.toml << "RUSTCONFIG"
[build]
rustc-wrapper = "sccache"  # Optional, for build caching

[target.x86_64-unknown-freebsd]
linker = "clang"

[unstable]
build-std = ["std", "panic_abort"]
build-std-features = ["panic_immediate_abort"]
RUSTCONFIG

        # Set up environment for bootstrap builds
        echo 'export RUSTC_BOOTSTRAP=1' >> /Users/live/.profile
        echo 'export RUST_BACKTRACE=1' >> /Users/live/.profile
    fi
fi

# Install VSCode or Code-Server
if [ -d /Files/Compile/Sources/vscode-* ]; then
    echo "Setting up VSCode development environment..."

    # Find the VSCode directory
    for vscode_dir in /Files/Compile/Sources/vscode-*; do
        if [ -d "$vscode_dir" ]; then
            cd "$vscode_dir"
            break
        fi
    done

    # Create VSCode installation
    mkdir -p /Programs/VSCode/Current/bin
    # VSCode requires Node.js and complex build, we'll create a basic setup
    # In a real scenario, this would build from source
    echo '#!/bin/sh' > /Programs/VSCode/Current/bin/code
    echo 'echo "VSCode is not fully built in this image. Use code-server instead."' >> /Programs/VSCode/Current/bin/code
    chmod +x /Programs/VSCode/Current/bin/code

    # Create symlink for VSCode
    ln -sf /Programs/VSCode/Current/bin/code /System/Links/Executables/code 2>/dev/null || true
fi

# Install Code-Server as alternative
if [ -d /Files/Compile/Sources/code-server-* ]; then
    echo "Setting up Code-Server development environment..."

    # Find the code-server directory
    for code_dir in /Files/Compile/Sources/code-server-*; do
        if [ -d "$code_dir" ]; then
            cd "$code_dir"
            break
        fi
    done

    # Extract and install code-server
    tar -xzf *.tar.gz --strip-components=1 -C /Programs/CodeServer/Current 2>/dev/null || true
    if [ -f "code-server" ]; then
        mkdir -p /Programs/CodeServer/Current/bin
        cp code-server /Programs/CodeServer/Current/bin/
        ln -sf /Programs/CodeServer/Current/bin/code-server /System/Links/Executables/code-server 2>/dev/null || true
    fi
fi

# Create a default Cargo configuration for release builds
mkdir -p /Users/live/.cargo
cat > /Users/live/.cargo/config.toml << "CARGOCONFIG"
[build]
target-dir = "/tmp/cargo-target"

[profile.dev]
debug = true

[profile.release]
lto = true
codegen-units = 1
panic = "abort"

[target.x86_64-unknown-freebsd]
rustflags = ["-C", "target-feature=+crt-static"]
CARGOCONFIG

# Create a sample release configuration
mkdir -p /Users/live/.cargo
cat > /Users/live/.cargo/release.toml << "RELEASECONFIG"
[build]
target = "x86_64-unknown-freebsd"

[profile.release]
lto = true
codegen-units = 1
panic = "abort"
strip = true
RELEASECONFIG

# Add Rust to user profiles
echo 'export PATH="$PATH:/Programs/Rust/Current/bin"' >> /Users/live/.profile
echo 'export RUSTC_BOOTSTRAP=1' >> /Users/live/.profile
echo 'export CARGO_HOME="$HOME/.cargo"' >> /Users/live/.profile
echo 'export RUSTUP_HOME="$HOME/.rustup"' >> /Users/live/.profile

# Install GoboHide if available
if [ -d /Files/Compile/Sources/GoboHide-* ]; then
    echo "Setting up GoboHide filesystem utility..."

    # Find the GoboHide directory
    for gobo_dir in /Files/Compile/Sources/GoboHide-*; do
        if [ -d "$gobo_dir" ]; then
            cd "$gobo_dir"
            break
        fi
    done

    # Create GoboHide installation
    mkdir -p /Programs/GoboHide/Current/bin
    mkdir -p /Programs/GoboHide/Current/lib

    # Copy GoboHide binary if it exists
    if [ -f "GoboHide" ]; then
        cp GoboHide /Programs/GoboHide/Current/bin/
    else
        # If not built, create a placeholder with instructions
        cat > /Programs/GoboHide/Current/bin/GoboHide << "GHOBSRC"
#!/bin/sh
echo "GoboHide is not fully built in this image."
echo "To build GoboHide on FreeBSD:"
echo "1. Install fusefs-libs and development tools"
echo "2. Navigate to the GoboHide source directory"
echo "3. Run: make && make install"
GHOBSRC
        chmod +x /Programs/GoboHide/Current/bin/GoboHide
    fi

    # Create symlink for GoboHide
    ln -sf /Programs/GoboHide/Current/bin/GoboHide /System/Links/Executables/GoboHide 2>/dev/null || true

    # Add GoboHide to user profiles
    echo 'export PATH="$PATH:/Programs/GoboHide/Current/bin"' >> /Users/live/.profile
fi

# Install nano editor if available
if [ -d /Files/Compile/Sources/nano-* ]; then
    echo "Setting up nano text editor..."

    # Find the nano directory
    for nano_dir in /Files/Compile/Sources/nano-*; do
        if [ -d "$nano_dir" ]; then
            cd "$nano_dir"
            break
        fi
    done

    # Create nano installation
    mkdir -p /Programs/Nano/Current/bin
    mkdir -p /Programs/Nano/Current/lib

    # If nano was compiled, copy it
    if [ -f "src/nano" ]; then
        cp src/nano /Programs/Nano/Current/bin/
    else
        # If not built, create a placeholder
        cat > /Programs/Nano/Current/bin/nano << "NANOSRC"
#!/bin/sh
echo "Nano editor is not fully built in this image."
echo "Nano should be available after proper compilation."
NANOSRC
        chmod +x /Programs/Nano/Current/bin/nano
    fi

    # Create symlink for nano
    ln -sf /Programs/Nano/Current/bin/nano /System/Links/Executables/nano 2>/dev/null || true

    # Add nano to user profiles as default editor
    echo 'export EDITOR=nano' >> /Users/live/.profile
    echo 'export PATH="$PATH:/Programs/Nano/Current/bin"' >> /Users/live/.profile
fi

# Run AlienVFS integration finalization
if [ -x /System/Setup/finalize_alien_integration.sh ]; then
    /System/Setup/finalize_alien_integration.sh
fi

# Create a script to install Alien packages during ISO building
cat > ${ROOT}/System/Setup/install_alien_packages.sh << "EOF"
#!/bin/sh
# Script to install Alien packages during ISO building

# Check if we have the Alien command available
if [ -x /System/Links/Executables/Alien ]; then
    echo "Alien command is available, installing packages..."

    # Create a list of packages to install
    cat > /tmp/alien_install_list.txt << "INSTALLLIST"
PIP3:requests
PIP3:beautifulsoup4
PIP3:numpy
PIP3:pandas
PIP3:matplotlib
PIP3:scipy
LuaRocks:lgi
LuaRocks:luafilesystem
CPAN:JSON
CPAN:XML::Parser
Cargo:cargo-update
INSTALLLIST

    # Install each package
    while IFS= read -r package; do
        if [ -n "$package" ]; then
            echo "Installing $package..."
            # Use the Alien command to install the package
            /System/Links/Executables/Alien --install "$package" 2>/dev/null || echo "Failed to install $package"
        fi
    done < /tmp/alien_install_list.txt

    rm -f /tmp/alien_install_list.txt
else
    echo "Alien command not available, skipping Alien package installation"
fi

echo "Alien package installation completed (or skipped)."
EOF

chmod +x ${ROOT}/System/Setup/install_alien_packages.sh

# Run the Alien package installation script
if [ -x /System/Setup/install_alien_packages.sh ]; then
    /System/Setup/install_alien_packages.sh
fi

echo "GoboBSD system setup completed!"
echo "You can now exit the chroot and run create_bootdir.sh"
EOF

chmod +x ${ROOT}/System/Setup/finalize_chroot.sh

echo "Final system setup completed."

exit 0