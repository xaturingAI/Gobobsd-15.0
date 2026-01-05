#!/bin/sh

umask 022

if [ ! -f "${bootstrapScriptsDir}/11_setup_recipe_tools.sh" ]; then
  echo "Please execute $0 from its directory"
  exit 201
fi

. ./bootstrap_env.inc

echo "Setting up Recipe Tools, Recipe Viewer, and Review Panel for FreeBSD compatibility..."

# Function to extract and process zip files
extract_and_process_zip() {
    local zip_file="$1"
    local package_name="$2"
    local description="$3"
    
    echo "Processing $description ($package_name) from $zip_file..."
    
    # Create a temporary directory for extraction
    TEMP_DIR=$(mktemp -d "/tmp/${package_name}_XXXXXX")
    cd "$TEMP_DIR"
    
    # Extract the zip file
    unzip -q "$zip_file"
    
    # Find the extracted directory (usually the first directory created)
    EXTRACTED_DIR=$(find . -maxdepth 1 -type d -not -name "$(basename $TEMP_DIR)" | head -n 1)
    if [ -n "$EXTRACTED_DIR" ]; then
        cd "$EXTRACTED_DIR"
        
        echo "  Working in extracted directory: $EXTRACTED_DIR"
        
        # Look for any shell scripts and update them for FreeBSD compatibility
        for script_file in $(find . -name "*.sh" -type f); do
            if [ -f "$script_file" ]; then
                echo "    Updating shell script for FreeBSD: $script_file"
                # Replace Linux-specific commands with FreeBSD equivalents
                sed -i.bak 's|/proc/meminfo|/compat/linux/proc/meminfo|g' "$script_file" 2>/dev/null || true
                sed -i.bak 's|df -h|df -h|g' "$script_file" 2>/dev/null || true  # Same on FreeBSD
                sed -i.bak 's|grep -P|grep -E|g' "$script_file" 2>/dev/null || true  # FreeBSD grep doesn't have -P
                sed -i.bak 's|ps -e|ps ax|g' "$script_file" 2>/dev/null || true  # Different ps options
                sed -i.bak 's|ps -ef|ps aux|g' "$script_file" 2>/dev/null || true  # Different ps options
            fi
        done
        
        # Look for any PHP files that might need FreeBSD-specific configuration
        for php_file in $(find . -name "*.php" -type f); do
            if [ -f "$php_file" ]; then
                echo "    Checking PHP file for FreeBSD compatibility: $php_file"
                # Add FreeBSD-specific configuration if needed
                if grep -q "linux\|/proc\|/sys" "$php_file"; then
                    echo "      Found Linux-specific elements in $php_file"
                fi
            fi
        done
        
        # Look for any configuration files
        for conf_file in $(find . -name "*.conf" -o -name "*.ini" -type f); do
            if [ -f "$conf_file" ]; then
                echo "    Checking config file: $conf_file"
                # Update paths if needed
                sed -i.bak 's|/etc/|/usr/local/etc/|g' "$conf_file" 2>/dev/null || true
            fi
        done
        
        # Copy the processed package to the appropriate location
        if [ -d "$ROOT/Programs" ]; then
            # Create a directory for the package in Programs
            PKG_DEST_DIR="$ROOT/Programs/${package_name}/Current"
            mkdir -p "$PKG_DEST_DIR"
            
            # Copy all files to the destination
            cp -r ./* "$PKG_DEST_DIR/" 2>/dev/null || cp -r . "$PKG_DEST_DIR/"
            
            # Create a symlink to the versioned directory
            PKG_VERSION_DIR="$ROOT/Programs/${package_name}/1.0"
            ln -sfn "Current" "$ROOT/Programs/${package_name}/Current"
            
            echo "    Copied $description to: $PKG_DEST_DIR"
        else
            echo "    Warning: Programs directory not found, copying to Sources instead"
            # Copy to sources directory if Programs doesn't exist yet
            PKG_DEST_DIR="$ROOT/Files/Compile/Sources/${package_name}-1.0"
            mkdir -p "$PKG_DEST_DIR"
            cp -r ./* "$PKG_DEST_DIR/" 2>/dev/null || cp -r . "$PKG_DEST_DIR/"
        fi
        
        cd ..
    fi
    
    # Clean up
    cd - > /dev/null
    rm -rf "$TEMP_DIR"
}

# Process RecipeTools
if [ -f "../Resources/RecipeTools-master.zip" ]; then
    extract_and_process_zip "../Resources/RecipeTools-master.zip" "RecipeTools" "Recipe Tools"
else
    echo "RecipeTools-master.zip not found, skipping..."
fi

# Process RecipeViewer
if [ -f "../Resources/RecipeViewer-master.zip" ]; then
    extract_and_process_zip "../Resources/RecipeViewer-master.zip" "RecipeViewer" "Recipe Viewer"
else
    echo "RecipeViewer-master.zip not found, skipping..."
fi

# Process ReviewPanel
if [ -f "../Resources/ReviewPanel-master.zip" ]; then
    extract_and_process_zip "../Resources/ReviewPanel-master.zip" "ReviewPanel" "Review Panel"
else
    echo "ReviewPanel-master.zip not found, skipping..."
fi

# Create symlinks in the executables directory for any binaries
echo "Creating symlinks for recipe tools in system executables..."

# For RecipeTools, create symlinks to the bin directory if it exists
if [ -d "$ROOT/Programs/RecipeTools/Current/bin" ]; then
    mkdir -p "$ROOT/System/Links/Executables"
    for bin_file in "$ROOT/Programs/RecipeTools/Current/bin/"*; do
        if [ -f "$bin_file" ] && [ -x "$bin_file" ]; then
            bin_name=$(basename "$bin_file")
            ln -sfn "/Programs/RecipeTools/Current/bin/$bin_name" "$ROOT/System/Links/Executables/$bin_name"
            echo "  Created symlink: $bin_name -> /Programs/RecipeTools/Current/bin/$bin_name"
        fi
    done
fi

# Check if there are any Python files that need to be updated for Python 3
echo "Checking for Python files that need Python 3 compatibility..."

for py_file in $(find "$ROOT/Programs" -name "*.py" -type f 2>/dev/null); do
    if [ -f "$py_file" ]; then
        echo "  Checking Python file: $py_file"
        
        # Update shebangs to use Python 3
        if head -n 1 "$py_file" | grep -q "python"; then
            sed -i.bak '1s|#!/usr/bin/python$|#!/usr/bin/env python3|' "$py_file" 2>/dev/null || \
            sed -i.bak '1s|#!/usr/bin/python2$|#!/usr/bin/env python3|' "$py_file" 2>/dev/null || \
            sed -i.bak '1s|#!/usr/bin/env python$|#!/usr/bin/env python3|' "$py_file" 2>/dev/null || \
            sed -i.bak '1s|#!/usr/bin/env python2$|#!/usr/bin/env python3|' "$py_file" 2>/dev/null
        fi
        
        # Check for Python 2 specific syntax and update to Python 3
        if grep -q "print " "$py_file" && ! grep -q "print(" "$py_file"; then
            echo "    Converting Python 2 print statements in $py_file"
            # This is a simplified conversion - in practice, more complex parsing would be needed
            sed -i.bak -E 's/^([[:space:]]*)(print )([^#"].*)$/\1print(\3)/g' "$py_file" 2>/dev/null
            sed -i.bak -E 's/^([[:space:]]*)(print )([^#"]*"[^"]*")/\1print(\3)/g' "$py_file" 2>/dev/null
        fi
        
        # Convert other Python 2 to Python 3 constructs
        sed -i.bak 's/xrange(/range(/g' "$py_file" 2>/dev/null
        sed -i.bak 's/.iteritems(/.items(/g' "$py_file" 2>/dev/null
        sed -i.bak 's/.iterkeys(/.keys(/g' "$py_file" 2>/dev/null
        sed -i.bak 's/.itervalues(/.values(/g' "$py_file" 2>/dev/null
        sed -i.bak 's/unicode(/str(/g' "$py_file" 2>/dev/null
    fi
done

echo "Recipe tools setup completed with FreeBSD compatibility!"
echo "Recipe Tools, Recipe Viewer, and Review Panel have been processed and installed."