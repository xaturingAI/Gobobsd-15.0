#!/bin/sh

umask 022

if [ ! -f "${bootstrapScriptsDir}/14_handle_zip_packages.sh" ]; then
  echo "Please execute $0 from its directory"
  exit 201
fi

. ./bootstrap_env.inc

echo "Handling GoboBSD .zip packages and applying patches..."

# Function to extract and process a .zip package
process_zip_package() {
    local zip_file="$1"
    local package_name="$2"
    local description="$3"
    
    if [ -f "$zip_file" ]; then
        echo "Processing $description package: $(basename $zip_file)"
        
        # Create a temporary directory for extraction
        TEMP_DIR=$(mktemp -d "/tmp/${package_name}_XXXXXX")
        
        # Extract the zip file
        cd "$TEMP_DIR"
        unzip -q "$zip_file" >/dev/null 2>&1
        
        # Find the extracted directory (usually the first directory created)
        EXTRACTED_DIR=$(find . -maxdepth 1 -type d -not -name "$(basename $TEMP_DIR)" | head -n 1)
        if [ -n "$EXTRACTED_DIR" ]; then
            cd "$EXTRACTED_DIR"
            
            # Determine the package directory name for the Sources directory
            PKG_DIR_NAME=$(basename "$EXTRACTED_DIR")
            
            # Create the destination directory in Sources
            PKG_DEST_DIR="$ROOT/Files/Compile/Sources/$PKG_DIR_NAME"
            
            if [ ! -d "$PKG_DEST_DIR" ]; then
                echo "  Copying $description to Sources directory: $PKG_DEST_DIR"
                mkdir -p "$PKG_DEST_DIR"
                
                # Copy all extracted files to the Sources directory
                cp -r ./* "$PKG_DEST_DIR/" 2>/dev/null || cp -r . "$PKG_DEST_DIR/" 2>/dev/null
                
                # Create Patches directory and copy relevant patches
                mkdir -p "$PKG_DEST_DIR/Patches"
                
                # Look for patches that match this package name
                for patch_file in ../Resources/*"$package_name"*-FreeBSD*.patch; do
                    if [ -f "$patch_file" ]; then
                        echo "    Copying patch: $(basename $patch_file)"
                        cp "$patch_file" "$PKG_DEST_DIR/Patches/"
                    fi
                done
                
                # Also look for generic patches that might apply
                for patch_file in ../Resources/*FreeBSD*.patch; do
                    if [ -f "$patch_file" ]; then
                        patch_basename=$(basename "$patch_file")
                        # Check if this patch is specific to this package or generic
                        if echo "$patch_basename" | grep -qi "$package_name"; then
                            echo "    Copying package-specific patch: $patch_basename"
                            cp "$patch_file" "$PKG_DEST_DIR/Patches/"
                        fi
                    fi
                done
                
                # Create symlinks to patches in the main directory as well
                for patch_file in "$PKG_DEST_DIR/Patches/"*.patch; do
                    if [ -f "$patch_file" ]; then
                        patch_name=$(basename "$patch_file")
                        if [ ! -L "$PKG_DEST_DIR/$patch_name" ] && [ ! -f "$PKG_DEST_DIR/$patch_name" ]; then
                            ln -s "Patches/$patch_name" "$PKG_DEST_DIR/$patch_name" 2>/dev/null || cp "$patch_file" "$PKG_DEST_DIR/$patch_name" 2>/dev/null
                        fi
                    fi
                done
                
                echo "  $description package prepared for compilation with patches"
            else
                echo "  $description already exists in Sources, skipping extraction"
            fi
        else
            echo "  Warning: Could not find extracted directory for $package_name"
        fi
        
        # Clean up
        cd - > /dev/null
        rm -rf "$TEMP_DIR"
    else
        echo "$package_name .zip file not found: $zip_file"
    fi
}

# Process all .zip packages in the Resources directory
echo "Processing .zip packages from Resources directory..."

# Process Lua-GoboLinux package
if [ -f "../Resources/Lua-GoboLinux-master.zip" ]; then
    process_zip_package "../Resources/Lua-GoboLinux-master.zip" "Lua-GoboLinux" "Lua GoboLinux"
else
    echo "Lua-GoboLinux-master.zip not found, checking alternative location..."
    if [ -f "../Resources/gobo packages in zip/Lua-GoboLinux-master.zip" ]; then
        process_zip_package "../Resources/gobo packages in zip/Lua-GoboLinux-master.zip" "Lua-GoboLinux" "Lua GoboLinux"
    fi
fi

# Process RecipeTools package
if [ -f "../Resources/RecipeTools-master.zip" ]; then
    process_zip_package "../Resources/RecipeTools-master.zip" "RecipeTools" "Recipe Tools"
else
    echo "RecipeTools-master.zip not found, checking alternative location..."
    if [ -f "../Resources/gobo packages in zip/RecipeTools-master.zip" ]; then
        process_zip_package "../Resources/gobo packages in zip/RecipeTools-master.zip" "RecipeTools" "Recipe Tools"
    fi
fi

# Process RecipeViewer package
if [ -f "../Resources/RecipeViewer-master.zip" ]; then
    process_zip_package "../Resources/RecipeViewer-master.zip" "RecipeViewer" "Recipe Viewer"
else
    echo "RecipeViewer-master.zip not found, checking alternative location..."
    if [ -f "../Resources/gobo packages in zip/RecipeViewer-master.zip" ]; then
        process_zip_package "../Resources/gobo packages in zip/RecipeViewer-master.zip" "RecipeViewer" "Recipe Viewer"
    fi
fi

# Process ReviewPanel package
if [ -f "../Resources/ReviewPanel-master.zip" ]; then
    process_zip_package "../Resources/ReviewPanel-master.zip" "ReviewPanel" "Review Panel"
else
    echo "ReviewPanel-master.zip not found, checking alternative location..."
    if [ -f "../Resources/gobo packages in zip/ReviewPanel-master.zip" ]; then
        process_zip_package "../Resources/gobo packages in zip/ReviewPanel-master.zip" "ReviewPanel" "Review Panel"
    fi
fi

# Process AbsTK package
if [ -f "../Resources/AbsTK-master.zip" ]; then
    process_zip_package "../Resources/AbsTK-master.zip" "AbsTK" "AbsTK"
else
    echo "AbsTK-master.zip not found, checking alternative location..."
    if [ -f "../Resources/gobo packages in zip/AbsTK-master.zip" ]; then
        process_zip_package "../Resources/gobo packages in zip/AbsTK-master.zip" "AbsTK" "AbsTK"
    fi
fi

# Process ViewFS package
if [ -f "../Resources/ViewFS-master.zip" ]; then
    process_zip_package "../Resources/ViewFS-master.zip" "ViewFS" "ViewFS"
else
    echo "ViewFS-master.zip not found, checking alternative location..."
    if [ -f "../Resources/gobo packages in zip/ViewFS-master.zip" ]; then
        process_zip_package "../Resources/gobo packages in zip/ViewFS-master.zip" "ViewFS" "ViewFS"
    fi
fi

# Process Files package
if [ -f "../Resources/Files-master.zip" ]; then
    process_zip_package "../Resources/Files-master.zip" "Files" "Files"
else
    echo "Files-master.zip not found, checking alternative location..."
    if [ -f "../Resources/gobo packages in zip/Files-master.zip" ]; then
        process_zip_package "../Resources/gobo packages in zip/Files-master.zip" "Files" "Files"
    fi
fi

# Process packages from the gobo packages in zip directory
echo "Processing .zip packages from gobo packages in zip directory..."

for zip_file in ../Resources/gobo\ packages\ in\ zip/*.zip; do
    if [ -f "$zip_file" ]; then
        zip_basename=$(basename "$zip_file")
        package_name=$(echo "$zip_basename" | sed 's/\.zip$//' | sed 's/-master$//')
        
        echo "Processing package from gobo packages directory: $zip_basename"
        
        # Create a temporary directory for extraction
        TEMP_DIR=$(mktemp -d "/tmp/${package_name}_XXXXXX")
        
        cd "$TEMP_DIR"
        unzip -q "$zip_file" >/dev/null 2>&1
        
        # Find the extracted directory
        EXTRACTED_DIR=$(find . -maxdepth 1 -type d -not -name "$(basename $TEMP_DIR)" | head -n 1)
        if [ -n "$EXTRACTED_DIR" ]; then
            cd "$EXTRACTED_DIR"
            
            # Determine the package directory name for the Sources directory
            PKG_DIR_NAME=$(basename "$EXTRACTED_DIR")
            
            # Create the destination directory in Sources
            PKG_DEST_DIR="$ROOT/Files/Compile/Sources/$PKG_DIR_NAME"
            
            if [ ! -d "$PKG_DEST_DIR" ]; then
                echo "  Copying $package_name to Sources directory: $PKG_DEST_DIR"
                mkdir -p "$PKG_DEST_DIR"
                
                # Copy all extracted files to the Sources directory
                cp -r ./* "$PKG_DEST_DIR/" 2>/dev/null || cp -r . "$PKG_DEST_DIR/" 2>/dev/null
                
                # Create Patches directory and copy relevant patches
                mkdir -p "$PKG_DEST_DIR/Patches"
                
                # Look for patches that match this package name
                for patch_file in ../Resources/*"$package_name"*-FreeBSD*.patch; do
                    if [ -f "$patch_file" ]; then
                        echo "    Copying patch: $(basename $patch_file)"
                        cp "$patch_file" "$PKG_DEST_DIR/Patches/"
                    fi
                done
                
                # Create symlinks to patches
                for patch_file in "$PKG_DEST_DIR/Patches/"*.patch; do
                    if [ -f "$patch_file" ]; then
                        patch_name=$(basename "$patch_file")
                        if [ ! -L "$PKG_DEST_DIR/$patch_name" ] && [ ! -f "$PKG_DEST_DIR/$patch_name" ]; then
                            ln -s "Patches/$patch_name" "$PKG_DEST_DIR/$patch_name" 2>/dev/null || cp "$patch_file" "$PKG_DEST_DIR/$patch_name" 2>/dev/null
                        fi
                    fi
                done
                
                echo "  $package_name package prepared for compilation with patches"
            else
                echo "  $package_name already exists in Sources, skipping extraction"
            fi
        else
            echo "  Warning: Could not find extracted directory for $package_name"
        fi
        
        # Clean up
        cd - > /dev/null
        rm -rf "$TEMP_DIR"
    fi
done

# Create a manifest of all processed packages
echo "Creating package manifest..."
MANIFEST_FILE="$ROOT/System/Settings/gobobsd_zip_packages_manifest.txt"
mkdir -p "$ROOT/System/Settings"
cat > "$MANIFEST_FILE" << EOF
# GoboBSD ZIP Packages Manifest
# This file lists all ZIP packages processed and their patch status

$(find $ROOT/Files/Compile/Sources -name "Patches" -type d -exec sh -c 'for dirpath; do echo "$(basename $(dirname "$dirpath")) - $(ls "$(dirname "$dirpath")/Patches/"*.patch 2>/dev/null | wc -l) patches"; done' _ {} + 2>/dev/null)

EOF

echo "All .zip packages processed and patches organized for GoboLinux Compile system!"
echo "Packages are now in the Sources directory with patches in Patches subdirectories."
echo "The GoboLinux Compile system will automatically apply these patches during compilation."