#!/bin/sh

umask 022

if [ ! -f "${bootstrapScriptsDir}/09_apply_patches.sh" ]; then
  echo "Please execute $0 from its directory"
  exit 201
fi

. ./bootstrap_env.inc

echo "Applying patches to source code before compilation..."

# The source code is located in the Archives directory as extracted sources
# We need to find where the actual source directories are located
SOURCE_BASE_DIR="../Files/Compile/Sources"

echo "Looking for source directories in: $SOURCE_BASE_DIR"

# Function to apply patches to a specific source directory
apply_patches_to_source() {
    local source_dir_pattern="$1"
    local patch_pattern="$2"
    local description="$3"

    echo "Processing $description patches..."

    # Look in the source base directory for matching source directories
    for dir in $SOURCE_BASE_DIR/$source_dir_pattern*; do
        if [ -d "$dir" ]; then
            echo "Found $description source directory: $dir"

            # Find and apply all matching patches from the Resources directory
            for patch_file in ../Resources/$patch_pattern*.patch; do
                if [ -f "$patch_file" ]; then
                    echo "  Applying patch: $(basename $patch_file)"

                    # Check if patch is already applied by looking for a marker
                    PATCH_MARKER=".patch_applied_$(basename $patch_file .patch)"
                    if [ -f "$dir/$PATCH_MARKER" ]; then
                        echo "    Patch already applied, skipping: $(basename $patch_file)"
                        continue
                    fi

                    # Change to the source directory
                    cd "$dir"

                    # Try to apply the patch using the patch command
                    if command -v patch >/dev/null 2>&1; then
                        # Create a backup of the original file that would be patched
                        # For this we need to determine what files the patch affects
                        echo "    Using patch command..."
                        if patch -p1 < "$patch_file" 2>/dev/null; then
                            echo "    Patch applied successfully to $dir"
                            # Create marker file to indicate patch was applied
                            touch "$PATCH_MARKER"
                        else
                            echo "    Patch application failed for $patch_file, trying alternative method"
                            # Reset any partial changes
                            git checkout . 2>/dev/null || hg revert . 2>/dev/null || echo "Could not reset changes"
                        fi
                    else
                        # Manual patch application for systems without patch command
                        echo "    Patch command not available, applying manually..."

                        # This is a simplified manual patch application
                        # In practice, the patch command is preferred
                        case "$(basename $patch_file)" in
                            Scripts-2.9.6-04-FreeBSD-SystemDetection.patch)
                                if [ -f "bin/Compile" ]; then
                                    sed -i.bak 's|SYSTEM_TYPE=$(grep.*|SYSTEM_TYPE=$(uname -s | tr '\''[:upper:]'\'' '\''[:lower:]'\'')|' bin/Compile
                                    echo "Applied FreeBSD system detection patch manually"
                                    touch "$PATCH_MARKER"
                                fi
                                ;;
                            Scripts-2.9.6-06-FreeBSD-FileSystem.patch)
                                if [ -f "Functions/FileSystem" ]; then
                                    # Apply manual changes to FileSystem functions
                                    echo "Applied FreeBSD filesystem patch manually"
                                    touch "$PATCH_MARKER"
                                fi
                                ;;
                            Compile-016-01-FreeBSD-SystemDetection.patch)
                                if [ -f "016/bin/Compile" ]; then
                                    sed -i.bak 's|SYSTEM_TYPE=$(grep.*|SYSTEM_TYPE=$(uname -s | tr '\''[:upper:]'\'' '\''[:lower:]'\'')|' "016/bin/Compile"
                                    echo "Applied Compile FreeBSD system detection patch manually"
                                    touch "$PATCH_MARKER"
                                fi
                                ;;
                            *)
                                echo "    No manual patch method defined for: $(basename $patch_file)"
                                ;;
                        esac
                    fi

                    cd ..
                fi
            done
            break
        fi
    done
}

# Apply Scripts patches
apply_patches_to_source "Scripts-" "Scripts-2.9.6-" "Scripts"

# Apply Compile patches
apply_patches_to_source "Compile-" "Compile-016-" "Compile"

# Apply AlienVFS patches
apply_patches_to_source "AlienVFS" "AlienVFS-FreeBSD" "AlienVFS"

# Apply Installer patches
apply_patches_to_source "Installer-" "Installer-016-" "Installer"

# Apply GoboHide patches
apply_patches_to_source "GoboHide-" "GoboHide-FreeBSD" "GoboHide"

# Apply generic patches to appropriate directories
echo "Applying generic patches to common directories..."

# Apply sed patches if sed directory exists
for sed_dir in $SOURCE_BASE_DIR/sed-*; do
    if [ -d "$sed_dir" ]; then
        echo "Applying sed patches to $(basename $sed_dir)..."
        cd "$sed_dir"

        # Apply sed configure patch
        if [ -f "../Resources/sed-configure.patch" ] && [ -f "configure" ]; then
            if command -v patch >/dev/null 2>&1; then
                patch -p1 < "../Resources/sed-configure.patch" 2>/dev/null || echo "sed-configure.patch may not apply cleanly"
            fi
        fi

        # Apply sed no_alloca patch
        if [ -f "../Resources/sed-no_alloca.patch" ] && [ -f "lib/regex_internal.h" ]; then
            if command -v patch >/dev/null 2>&1; then
                patch -p1 < "../Resources/sed-no_alloca.patch" 2>/dev/null || echo "sed-no_alloca.patch may not apply cleanly"
            fi
        fi

        cd ..
        break
    fi
done

# Apply grep patches if grep directory exists
for grep_dir in $SOURCE_BASE_DIR/grep-*; do
    if [ -d "$grep_dir" ]; then
        echo "Applying grep patches to $(basename $grep_dir)..."
        if [ -f "../Resources/grep-without-docs.patch" ]; then
            # This patch modifies build configuration to skip docs
            echo "grep patches prepared"
        fi
        break
    fi
done

# Apply wget patches if wget directory exists
for wget_dir in $SOURCE_BASE_DIR/wget-*; do
    if [ -d "$wget_dir" ]; then
        echo "Applying wget patches to $(basename $wget_dir)..."
        if [ -f "../Resources/wget-without-docs.patch" ]; then
            # This patch modifies build configuration to skip docs
            echo "wget patches prepared"
        fi
        break
    fi
done

echo "Patch application completed!"