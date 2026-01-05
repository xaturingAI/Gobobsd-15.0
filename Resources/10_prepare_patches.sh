#!/bin/sh

umask 022

if [ ! -f "${bootstrapScriptsDir}/10_prepare_patches.sh" ]; then
  echo "Please execute $0 from its directory"
  exit 201
fi

. ./bootstrap_env.inc

echo "Preparing patches for GoboLinux Compile system..."

# Create a function to organize patches for specific packages
organize_patches_for_package() {
    local package_name="$1"
    local patch_pattern="$2"
    local description="$3"
    
    echo "Organizing patches for $description ($package_name)..."
    
    # Look for source directories that match the package name
    for source_dir in $ROOT/Files/Compile/Sources/${package_name}*; do
        if [ -d "$source_dir" ]; then
            echo "  Found source directory: $source_dir"
            
            # Create Patches directory if it doesn't exist
            mkdir -p "$source_dir/Patches"
            
            # Find all matching patches and copy them to the Patches directory
            for patch_file in ../Resources/${patch_pattern}*.patch; do
                if [ -f "$patch_file" ]; then
                    patch_basename=$(basename "$patch_file")
                    echo "    Copying patch: $patch_basename"
                    cp "$patch_file" "$source_dir/Patches/"
                    
                    # Create a symbolic link in the main source directory as well
                    if [ ! -L "$source_dir/$patch_basename" ]; then
                        ln -s "Patches/$patch_basename" "$source_dir/$patch_basename" 2>/dev/null || cp "$patch_file" "$source_dir/"
                    fi
                fi
            done
        fi
    done
}

# Organize Scripts patches
organize_patches_for_package "Scripts-" "Scripts-2.9.6-" "Scripts"

# Organize Compile patches
organize_patches_for_package "Compile-" "Compile-016-" "Compile"

# Organize AlienVFS patches
organize_patches_for_package "AlienVFS" "AlienVFS-FreeBSD" "AlienVFS"

# Organize Installer patches
organize_patches_for_package "Installer-" "Installer-016-" "Installer"

# Organize GoboHide patches
organize_patches_for_package "GoboHide-" "GoboHide-FreeBSD" "GoboHide"

# Organize generic patches
echo "Organizing generic patches..."

# For sed patches
for sed_dir in $ROOT/Files/Compile/Sources/sed-*; do
    if [ -d "$sed_dir" ]; then
        echo "  Found sed source directory: $sed_dir"
        mkdir -p "$sed_dir/Patches"
        
        # Copy sed-specific patches
        if [ -f "../Resources/sed-configure.patch" ]; then
            cp "../Resources/sed-configure.patch" "$sed_dir/Patches/"
        fi
        if [ -f "../Resources/sed-no_alloca.patch" ]; then
            cp "../Resources/sed-no_alloca.patch" "$sed_dir/Patches/"
        fi
        break
    fi
done

# For grep patches
for grep_dir in $ROOT/Files/Compile/Sources/grep-*; do
    if [ -d "$grep_dir" ]; then
        echo "  Found grep source directory: $grep_dir"
        mkdir -p "$grep_dir/Patches"
        
        # Copy grep-specific patches
        if [ -f "../Resources/grep-without-docs.patch" ]; then
            cp "../Resources/grep-without-docs.patch" "$grep_dir/Patches/"
        fi
        break
    fi
done

# For wget patches
for wget_dir in $ROOT/Files/Compile/Sources/wget-*; do
    if [ -d "$wget_dir" ]; then
        echo "  Found wget source directory: $wget_dir"
        mkdir -p "$wget_dir/Patches"
        
        # Copy wget-specific patches
        if [ -f "../Resources/wget-without-docs.patch" ]; then
            cp "../Resources/wget-without-docs.patch" "$wget_dir/Patches/"
        fi
        break
    fi
done

# Additionally, for some packages we need to create recipes that apply patches
echo "Creating patch application recipes where needed..."

# Create a general patch application helper
cat > "$ROOT/Files/Compile/Sources/apply_gobobsd_patches.sh" << 'PATCHHELPER'
#!/bin/sh
# Helper script to apply GoboBSD patches during compilation

SOURCE_DIR="$1"
PATCHES_DIR="$2"

if [ -z "$SOURCE_DIR" ] || [ -z "$PATCHES_DIR" ]; then
    echo "Usage: $0 <source_directory> <patches_directory>"
    exit 1
fi

if [ ! -d "$SOURCE_DIR" ]; then
    echo "Source directory does not exist: $SOURCE_DIR"
    exit 1
fi

if [ ! -d "$PATCHES_DIR" ]; then
    echo "Patches directory does not exist: $PATCHES_DIR"
    exit 0  # Not an error, just no patches to apply
fi

echo "Applying patches from $PATCHES_DIR to $SOURCE_DIR"

cd "$SOURCE_DIR"

for patch_file in "$PATCHES_DIR"/*.patch; do
    if [ -f "$patch_file" ]; then
        patch_name=$(basename "$patch_file")
        echo "Applying patch: $patch_name"
        
        if command -v patch >/dev/null 2>&1; then
            # Check if patch is already applied by looking for a marker
            patch_marker=".patch_applied_$(basename $patch_file .patch)"
            if [ -f "$patch_marker" ]; then
                echo "  Patch already applied, skipping: $patch_name"
                continue
            fi
            
            # Apply the patch
            if patch -p1 < "$patch_file"; then
                echo "  Patch applied successfully: $patch_name"
                touch "$patch_marker"
            else
                echo "  Warning: Failed to apply patch: $patch_name"
            fi
        else
            echo "  Warning: patch command not available, cannot apply: $patch_name"
        fi
    fi
done

PATCHHELPER

chmod +x "$ROOT/Files/Compile/Sources/apply_gobobsd_patches.sh"

echo "Patch organization completed!"
echo "Patches are now organized in Patches subdirectories for each source package."
echo "The GoboLinux Compile system should automatically apply these patches during compilation."