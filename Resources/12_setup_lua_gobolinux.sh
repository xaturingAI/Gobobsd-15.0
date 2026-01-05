#!/bin/sh

umask 022

if [ ! -f "${bootstrapScriptsDir}/11_setup_lua_gobolinux.sh" ]; then
  echo "Please execute $0 from its directory"
  exit 201
fi

. ./bootstrap_env.inc

echo "Setting up Lua-GoboLinux package with FreeBSD patches..."

# Check if the Lua-GoboLinux package exists in the Sources directory
LUA_GOBO_DIR=""
for dir in $ROOT/Files/Compile/Sources/Lua-GoboLinux-*; do
    if [ -d "$dir" ]; then
        LUA_GOBO_DIR="$dir"
        break
    fi
done

if [ -n "$LUA_GOBO_DIR" ]; then
    echo "Found Lua-GoboLinux source directory: $LUA_GOBO_DIR"
    
    cd "$LUA_GOBO_DIR"
    
    # Apply the FreeBSD filesystem patch to fix system call compatibility
    if [ -f "../Resources/Lua-GoboLinux-FreeBSD-FileSystem.patch" ]; then
        echo "Applying Lua-GoboLinux FreeBSD filesystem patch..."
        
        # Check if patch is already applied
        if [ ! -f ".patch_lua_gobolinux_applied" ]; then
            if command -v patch >/dev/null 2>&1; then
                # Apply the patch to the fs.c file
                cd src/fs
                if [ -f "fs.c" ]; then
                    # Create backup
                    cp fs.c fs.c.backup
                    
                    # Apply patch manually since we need to be careful with the diff
                    echo "Applying FreeBSD-specific changes to fs.c..."
                    
                    # Add FreeBSD includes
                    sed -i.bak '/#include <string.h>/a\
#ifdef __FreeBSD__\
  #include <sys/types.h>\
#else\
  #include <sys/sysmacros.h>\
#endif' fs.c
                    
                    # Update mknod calls for FreeBSD
                    sed -i.bak 's|(dev_t)NULL|0|g' fs.c
                    sed -i.bak 's|S_IFREG|(S_IFREG | 0644)|g' fs.c
                    
                    # Handle FIFO creation differently on FreeBSD
                    sed -i.bak 's|if (mknod(path,S_IFIFO,(dev_t)NULL) < 0)|if (mkfifo(path, 0666) < 0)|g' fs.c
                    
                    # Handle socket creation differently on FreeBSD
                    sed -i.bak '/if (mknod(path, S_IFSOCK,(dev_t)NULL) < 0)/a\
#ifdef __FreeBSD__\
        lua_pushnil(L);\
        lua_pushstring(L,"Socket creation through mknod not supported on FreeBSD");\
        return 2;\
#else' fs.c
                    
                    sed -i.bak '/return 2;/a\
#endif' fs.c
                    
                    # Handle block and character devices with proper permissions on FreeBSD
                    sed -i.bak 's|mknod(path, S_IFBLK|if (mknod(path, S_IFBLK | 0600|g' fs.c
                    sed -i.bak 's|mknod(path, S_IFCHR|if (mknod(path, S_IFCHR | 0600|g' fs.c
                    
                    echo "FreeBSD-specific changes applied to fs.c"
                else
                    echo "Warning: fs.c not found in src/fs directory"
                fi
                cd ../..  # Back to main directory
            else
                echo "Warning: patch command not available, manual patching needed"
            fi
            
            # Create marker file to indicate patch was applied
            touch ".patch_lua_gobolinux_applied"
        else
            echo "Patch already applied, skipping"
        fi
    else
        echo "Lua-GoboLinux FreeBSD patch not found, checking for alternative location..."
        if [ -f "../../Resources/Lua-GoboLinux-FreeBSD-FileSystem.patch" ]; then
            echo "Found patch in parent Resources directory"
        else
            echo "Lua-GoboLinux FreeBSD patch not found in expected locations"
        fi
    fi
    
    # Update the Makefile to handle FreeBSD-specific compilation
    if [ -f "Makefile" ]; then
        echo "Updating Makefile for FreeBSD compatibility..."
        sed -i.bak 's|gcc|$(CC)|g' Makefile 2>/dev/null || true
        # Add FreeBSD-specific compiler flags if needed
        if ! grep -q "FreeBSD" Makefile; then
            sed -i.bak '/^C_MODULES=/a\
# FreeBSD-specific settings\
ifeq ($(shell uname -s),FreeBSD)\
  CC?=cc\
  CFLAGS+=-DFREEBSD_BUILD\
endif' Makefile 2>/dev/null || true
        fi
    fi
    
    cd ..
    echo "Lua-GoboLinux setup completed with FreeBSD patches"
else
    echo "Lua-GoboLinux source directory not found, skipping setup"
fi

# Also check for the Lua-GoboLinux in the Resources directory that was mentioned
if [ -d "../gobo packages in zip/Lua-GoboLinux-master" ]; then
    echo "Found Lua-GoboLinux in Resources directory, preparing for compilation..."

    # Copy the package to the Sources directory if it's not already there
    if [ ! -d "$ROOT/Files/Compile/Sources/Lua-GoboLinux-master" ]; then
        echo "Copying Lua-GoboLinux to Sources directory..."
        mkdir -p "$ROOT/Files/Compile/Sources"
        cp -r "../gobo packages in zip/Lua-GoboLinux-master" "$ROOT/Files/Compile/Sources/Lua-GoboLinux-master"
    fi
    
    # Apply patches to the copied source
    cd "$ROOT/Files/Compile/Sources/Lua-GoboLinux-master"
    
    # Create Patches directory and copy relevant patches
    mkdir -p "Patches"
    if [ -f "../Resources/Lua-GoboLinux-FreeBSD-FileSystem.patch" ]; then
        cp "../Resources/Lua-GoboLinux-FreeBSD-FileSystem.patch" "Patches/"
    fi
    
    # Update configuration files for FreeBSD
    if [ -f "Settings/GoboLinux.conf" ]; then
        echo "Updating GoboLinux.conf for FreeBSD..."
        sed -i.bak 's|/System/Kernel/Status|/compat/linux/proc|g' Settings/GoboLinux.conf 2>/dev/null || true
        sed -i.bak 's|/System/Kernel/Objects|/compat/linux/sys|g' Settings/GoboLinux.conf 2>/dev/null || true
    fi
    
    if [ -f "Settings/system.conf" ]; then
        echo "Updating system.conf for FreeBSD..."
        # Add FreeBSD-specific paths if needed
        if ! grep -q "FreeBSD" Settings/system.conf; then
            sed -i.bak 's|{"proc"},|{"proc", "/compat/linux/proc"},|g' Settings/system.conf 2>/dev/null || true
            sed -i.bak 's|{"sys"},|{"sys", "/compat/linux/sys"},|g' Settings/system.conf 2>/dev/null || true
        fi
    fi
    
    cd - > /dev/null
fi

echo "Lua-GoboLinux package setup completed with FreeBSD compatibility patches!"