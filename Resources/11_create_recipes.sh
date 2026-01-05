#!/bin/sh

umask 022

if [ ! -f "${bootstrapScriptsDir}/11_create_recipes.sh" ]; then
  echo "Please execute $0 from its directory"
  exit 201
fi

. ./bootstrap_env.inc

echo "Creating GoboLinux recipes for FreeBSD packages..."

# Function to create a basic recipe for a package
create_recipe() {
    local package_name="$1"
    local version="$2"
    local description="$3"
    
    echo "Creating recipe for $package_name version $version..."
    
    # Find the source directory for this package
    for source_dir in $ROOT/Files/Compile/Sources/${package_name}-${version}*; do
        if [ -d "$source_dir" ]; then
            echo "  Found source directory: $source_dir"
            
            # Create Recipes directory if it doesn't exist
            RECIPE_DIR="$source_dir/Recipes"
            mkdir -p "$RECIPE_DIR"
            
            # Create a basic recipe file
            RECIPE_FILE="$RECIPE_DIR/${package_name}.recipe"
            cat > "$RECIPE_FILE" << RECIPE_EOF
#!/bin/bash
# Recipe for $package_name-$version
# Generated for GoboBSD (FreeBSD)

# Recipe metadata
Name=$package_name
Version=$version
Description="$description"
Author="GoboBSD Build System"
License="Various"

# Dependencies (if any)
Depends=()

# Recipe functions
Recipe_PreConfigure() {
    # Pre-configuration steps
    echo "Preparing $package_name-$version for FreeBSD..."
    
    # Apply any patches that were prepared earlier
    if [ -d "Patches" ]; then
        for patch_file in Patches/*.patch; do
            if [ -f "\$patch_file" ]; then
                echo "Applying patch: \$(basename \$patch_file)"
                if command -v patch >/dev/null 2>&1; then
                    patch -p1 < "\$patch_file" || echo "Warning: Failed to apply patch \$(basename \$patch_file)"
                else
                    echo "Warning: patch command not available"
                fi
            fi
        done
    fi
    
    # FreeBSD-specific pre-configuration
    if [ "\$(uname -s)" = "FreeBSD" ]; then
        echo "Running FreeBSD-specific pre-configuration..."
        
        # Fix common issues in source code for FreeBSD
        # Replace Linux-specific headers or functions
        find . -name "*.h" -o -name "*.c" -o -name "*.cpp" -o -name "*.cc" | xargs sed -i.bak -e 's|linux/|sys/|g' 2>/dev/null || true
        find . -name "*.h" -o -name "*.c" -o -name "*.cpp" -o -name "*.cc" | xargs sed -i.bak -e 's|sys/filio.h|sys/ioctl.h|g' 2>/dev/null || true
        
        # Handle autotools if present
        if [ -f "configure.ac" ] || [ -f "configure.in" ]; then
            if command -v autoreconf >/dev/null 2>&1; then
                echo "Regenerating autotools files for FreeBSD..."
                autoreconf -fiv || echo "Autoreconf failed, continuing anyway..."
            fi
        fi
    fi
}

Recipe_Configure() {
    # Configuration command
    echo "Configuring $package_name-$version..."
    
    # Determine configure options based on FreeBSD
    if [ "\$(uname -s)" = "FreeBSD" ]; then
        # FreeBSD-specific configure options
        ./configure --prefix=\$program_dir \\
                    --sysconfdir=/etc \\
                    --localstatedir=/var \\
                    --with-gnu-ld \\
                    CPPFLAGS="-I/usr/local/include" \\
                    LDFLAGS="-L/usr/local/lib" \\
                    CC="\$(command -v gcc || command -v clang)" \\
                    CXX="\$(command -v g++ || command -v clang++)"
    else
        # Default configure for other systems
        ./configure --prefix=\$program_dir
    fi
}

Recipe_Compile() {
    # Compilation command
    echo "Compiling $package_name-$version..."
    
    # Use appropriate make command for FreeBSD
    if [ "\$(uname -s)" = "FreeBSD" ]; then
        # Use gmake if available, otherwise regular make
        if command -v gmake >/dev/null 2>&1; then
            gmake -j\$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 1)
        else
            make -j\$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 1)
        fi
    else
        make -j\$(nproc 2>/dev/null || echo 1)
    fi
}

Recipe_Install() {
    # Installation command
    echo "Installing $package_name-$version..."
    
    # Use appropriate install command for FreeBSD
    if [ "\$(uname -s)" = "FreeBSD" ]; then
        # Use gmake if available for install, otherwise regular make
        if command -v gmake >/dev/null 2>&1; then
            gmake install
        else
            make install
        fi
    else
        make install
    fi
}

Recipe_PostInstall() {
    # Post-installation steps
    echo "Running post-installation steps for $package_name-$version..."
    
    # FreeBSD-specific post-install steps
    if [ "\$(uname -s)" = "FreeBSD" ]; then
        # Set proper permissions
        find \$program_dir -type f -executable -exec chmod 755 {} \\; 2>/dev/null || true
        find \$program_dir -type f -name "*.so*" -exec chmod 755 {} \\; 2>/dev/null || true
    fi
}

# Call the recipe functions in order
Recipe_PreConfigure
Recipe_Configure
Recipe_Compile
Recipe_Install
Recipe_PostInstall

echo "Recipe for $package_name-$version completed!"
RECIPE_EOF
            
            chmod +x "$RECIPE_FILE"
            echo "  Created recipe: $RECIPE_FILE"
            break
        fi
    done
}

# Create recipes for important packages
echo "Creating recipes for core packages..."

# Create recipe for core packages that are being compiled
for dir in $ROOT/Files/Compile/Sources/openssl-*; do
    if [ -d "$dir" ]; then
        pkg_name=$(basename "$dir" | cut -d'-' -f1)
        pkg_version=$(basename "$dir" | cut -d'-' -f2-)
        create_recipe "$pkg_name" "$pkg_version" "OpenSSL toolkit for secure communications"
        break
    fi
done

for dir in $ROOT/Files/Compile/Sources/ncurses-*; do
    if [ -d "$dir" ]; then
        pkg_name=$(basename "$dir" | cut -d'-' -f1)
        pkg_version=$(basename "$dir" | cut -d'-' -f2-)
        create_recipe "$pkg_name" "$pkg_version" "Text-based UI library"
        break
    fi
done

for dir in $ROOT/Files/Compile/Sources/bash-*; do
    if [ -d "$dir" ]; then
        pkg_name=$(basename "$dir" | cut -d'-' -f1)
        pkg_version=$(basename "$dir" | cut -d'-' -f2-)
        create_recipe "$pkg_name" "$pkg_version" "GNU Bourne-Again Shell"
        break
    fi
done

for dir in $ROOT/Files/Compile/Sources/Python-*; do
    if [ -d "$dir" ]; then
        pkg_name=$(basename "$dir" | cut -d'-' -f1)
        pkg_version=$(basename "$dir" | cut -d'-' -f2-)
        create_recipe "$pkg_name" "$pkg_version" "Python programming language"
        break
    fi
done

for dir in $ROOT/Files/Compile/Sources/coreutils-*; do
    if [ -d "$dir" ]; then
        pkg_name=$(basename "$dir" | cut -d'-' -f1)
        pkg_version=$(basename "$dir" | cut -d'-' -f2-)
        create_recipe "$pkg_name" "$pkg_version" "Basic file, shell and text manipulation utilities"
        break
    fi
done

for dir in $ROOT/Files/Compile/Sources/sed-*; do
    if [ -d "$dir" ]; then
        pkg_name=$(basename "$dir" | cut -d'-' -f1)
        pkg_version=$(basename "$dir" | cut -d'-' -f2-)
        create_recipe "$pkg_name" "$pkg_version" "Stream editor for filtering text"
        break
    fi
done

# Create recipes for other important packages
packages_to_recipe="
grep-.*:Text search utility
findutils-.*:File finding utilities
diffutils-.*:File comparison utilities
make-.*:Build automation tool
autoconf-.*:Configuration script generator
automake-.*:Makefile builder
m4-.*:Macro processor
libtool-.*:Library building tool
gawk-.*:Pattern scanning and processing language
tar-.*:Tape archiving utility
gzip-.*:Compression utility
bzip2-.*:Block-sorting file compressor
xz-.*:General-purpose data compression
"

echo "Creating recipes for additional packages..."
for package_line in $packages_to_recipe; do
    pkg_pattern=$(echo "$package_line" | cut -d':' -f1)
    pkg_desc=$(echo "$package_line" | cut -d':' -f2-)
    
    for dir in $ROOT/Files/Compile/Sources/$pkg_pattern*; do
        if [ -d "$dir" ]; then
            pkg_name=$(basename "$dir" | cut -d'-' -f1)
            pkg_version=$(basename "$dir" | cut -d'-' -f2-)
            create_recipe "$pkg_name" "$pkg_version" "$pkg_desc"
            break
        fi
    done
done

# Create a default recipe template that can be used by the Compile system
DEFAULT_RECIPE="$ROOT/Files/Compile/Sources/Default.recipe"
cat > "$DEFAULT_RECIPE" << 'DEFAULT_EOF'
#!/bin/bash
# Default GoboLinux Recipe Template for FreeBSD
# This template is used when no specific recipe exists

# Generic recipe that works for most autotools-based packages
Recipe_PreConfigure() {
    echo "Running pre-configure for $(basename $(pwd))"
    
    # Apply patches if available
    if [ -d "Patches" ]; then
        for patch_file in Patches/*.patch; do
            if [ -f "$patch_file" ]; then
                echo "Applying patch: $(basename $patch_file)"
                patch -p1 < "$patch_file" || echo "Patch failed: $(basename $patch_file)"
            fi
        done
    fi
    
    # FreeBSD-specific fixes
    if [ "$(uname -s)" = "FreeBSD" ]; then
        # Fix common build issues on FreeBSD
        # Look for and fix common header issues
        find . -name "*.h" -o -name "*.c" -o -name "*.cpp" -o -name "*.cc" | xargs sed -i.bak -e 's|#include <linux/|#include <sys/|g' 2>/dev/null || true
        
        # Regenerate build files if autotools are present
        if [ -f "configure.ac" ] || [ -f "configure.in" ]; then
            if command -v autoreconf >/dev/null 2>&1; then
                autoreconf -fiv || echo "Autoreconf failed, continuing..."
            fi
        fi
    fi
}

Recipe_Configure() {
    local prefix_arg="--prefix=$program_dir"
    local sysconfdir_arg="--sysconfdir=/etc"
    local localstatedir_arg="--localstatedir=/var"
    
    # FreeBSD-specific configure options
    if [ -f "./configure" ]; then
        echo "Configuring with: ./configure $prefix_arg $sysconfdir_arg $localstatedir_arg"
        ./configure $prefix_arg $sysconfdir_arg $localstatedir_arg \
            CPPFLAGS="-I/usr/local/include" \
            LDFLAGS="-L/usr/local/lib" \
            CC="$(command -v gcc || command -v clang)" \
            CXX="$(command -v g++ || command -v clang++)"
    elif [ -f "CMakeLists.txt" ]; then
        echo "Configuring with CMake..."
        cmake -DCMAKE_INSTALL_PREFIX="$program_dir" \
              -DCMAKE_BUILD_TYPE=Release .
    else
        echo "No standard build system detected, skipping configuration"
    fi
}

Recipe_Compile() {
    if [ -f "Makefile" ] || [ -f "makefile" ]; then
        # Use gmake on FreeBSD if available
        if [ "$(uname -s)" = "FreeBSD" ]; then
            if command -v gmake >/dev/null 2>&1; then
                gmake -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 1)
            else
                make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 1)
            fi
        else
            make -j$(nproc 2>/dev/null || echo 1)
        fi
    elif [ -f "CMakeLists.txt" ]; then
        if command -v cmake >/dev/null 2>&1; then
            cmake --build . --parallel
        fi
    else
        echo "No standard build system found, attempting generic build..."
        # Try common build commands
        make 2>/dev/null || gmake 2>/dev/null || echo "Build failed"
    fi
}

Recipe_Install() {
    if [ -f "Makefile" ] || [ -f "makefile" ]; then
        if [ "$(uname -s)" = "FreeBSD" ]; then
            if command -v gmake >/dev/null 2>&1; then
                gmake install
            else
                make install
            fi
        else
            make install
        fi
    elif [ -f "CMakeLists.txt" ]; then
        if command -v cmake >/dev/null 2>&1; then
            cmake --build . --target install
        fi
    fi
}

Recipe_PostInstall() {
    echo "Post-installation completed for $(basename $(pwd))"
}

# Execute the recipe steps
Recipe_PreConfigure
Recipe_Configure
Recipe_Compile
Recipe_Install
Recipe_PostInstall
DEFAULT_EOF

chmod +x "$DEFAULT_RECIPE"
echo "Created default recipe template: $DEFAULT_RECIPE"

echo "Recipe creation completed!"
echo "Recipes are now available for the GoboLinux Compile system to use during package compilation."