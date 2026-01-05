#!/bin/sh

umask 022

if [ ! -f "${bootstrapScriptsDir}/13_organize_compile_patches.sh" ]; then
  echo "Please execute $0 from its directory"
  exit 201
fi

. ./bootstrap_env.inc

echo "Organizing patches for GoboLinux Compile system..."

# Function to organize patches for a specific package
organize_patches_for_package() {
    local package_pattern="$1"
    local patch_pattern="$2"
    local description="$3"
    
    echo "Organizing patches for $description ($package_pattern)..."
    
    # Find source directories matching the pattern
    for source_dir in $ROOT/Files/Compile/Sources/$package_pattern*; do
        if [ -d "$source_dir" ]; then
            echo "  Found $description source directory: $(basename $source_dir)"
            
            # Create Patches directory if it doesn't exist
            mkdir -p "$source_dir/Patches"
            
            # Find and copy all matching patches from Resources
            for patch_file in ../Resources/$patch_pattern*.patch; do
                if [ -f "$patch_file" ]; then
                    patch_name=$(basename "$patch_file")
                    echo "    Copying patch: $patch_name"
                    
                    # Copy patch to the Patches directory
                    cp "$patch_file" "$source_dir/Patches/"
                    
                    # Create a symlink in the source directory root as well
                    if [ ! -L "$source_dir/$patch_name" ] && [ ! -f "$source_dir/$patch_name" ]; then
                        ln -s "Patches/$patch_name" "$source_dir/$patch_name" 2>/dev/null || cp "$patch_file" "$source_dir/$patch_name"
                    fi
                fi
            done
            
            # Check if there are any patches in the Patches directory
            if [ -d "$source_dir/Patches" ]; then
                patch_count=$(ls -1 "$source_dir/Patches/"*.patch 2>/dev/null | wc -l)
                if [ "$patch_count" -gt 0 ]; then
                    echo "    Applied $patch_count patches to $description"
                else
                    echo "    No patches found for $description"
                fi
            fi
        fi
    done
}

# Organize patches for Scripts packages
organize_patches_for_package "Scripts-*" "Scripts-2.9.6-" "Scripts"

# Organize patches for Compile packages
organize_patches_for_package "Compile-*" "Compile-016-" "Compile"

# Organize patches for AlienVFS packages
organize_patches_for_package "AlienVFS*" "AlienVFS-FreeBSD" "AlienVFS"

# Organize patches for Installer packages
organize_patches_for_package "Installer-*" "Installer-016-" "Installer"

# Organize patches for GoboHide packages
organize_patches_for_package "GoboHide-*" "GoboHide-FreeBSD" "GoboHide"

# Organize patches for system utilities
organize_patches_for_package "sed-*" "sed-" "Sed"
organize_patches_for_package "grep-*" "grep-" "Grep" 
organize_patches_for_package "wget-*" "wget-" "Wget"

# Organize patches for Lua-related packages
organize_patches_for_package "lua-*" "lua-" "Lua"
organize_patches_for_package "luarocks-*" "luarocks-" "LuaRocks"

# Organize patches for Rust-related packages
organize_patches_for_package "rust-*" "rust-" "Rust"
organize_patches_for_package "cargo-*" "cargo-" "Cargo"

# Organize patches for the Lua-GoboLinux package
organize_patches_for_package "Lua-GoboLinux-*" "Lua-GoboLinux" "Lua-GoboLinux"

# Create a master patch list for reference
echo "Creating patch manifest..."
PATCH_MANIFEST="$ROOT/System/Settings/gobobsd_patches_manifest.txt"
mkdir -p "$ROOT/System/Settings"
cat > "$PATCH_MANIFEST" << EOF
# GoboBSD Patches Manifest
# This file lists all patches applied to the system for reference

EOF

# Add entries for each patch type
for patch_file in ../Resources/*patch; do
    if [ -f "$patch_file" ]; then
        echo "$(basename $patch_file) - $(dirname $patch_file)" >> "$PATCH_MANIFEST"
    fi
done

echo "Patch organization completed!"
echo "Patches have been organized in Patches subdirectories for each source package."
echo "The GoboLinux Compile system will automatically apply these patches during compilation."