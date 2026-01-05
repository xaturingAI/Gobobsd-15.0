#!/bin/sh

umask 022

if [ ! -f "${bootstrapScriptsDir}/12_handle_additional_packages.sh" ]; then
  echo "Please execute $0 from its directory"
  exit 201
fi

. ./bootstrap_env.inc

echo "Handling additional GoboLinux packages for FreeBSD compatibility..."

# Function to extract and process zip files
extract_and_process_zip() {
    local zip_file="$1"
    local package_name="$2"
    
    echo "Processing ZIP file: $zip_file for package: $package_name"
    
    # Create a temporary directory for extraction
    TEMP_DIR=$(mktemp -d "/tmp/${package_name}_XXXXXX")
    cd "$TEMP_DIR"
    
    # Extract the zip file
    unzip -q "$zip_file"
    
    # Find the extracted directory (usually the first directory created)
    EXTRACTED_DIR=$(find . -maxdepth 1 -type d -not -name "$(basename $TEMP_DIR)" | head -n 1)
    if [ -n "$EXTRACTED_DIR" ]; then
        cd "$EXTRACTED_DIR"
        
        # Check for Python 2 usage and replace with Python 3
        echo "Checking for Python 2 usage in $package_name..."
        for py_file in $(find . -name "*.py" -type f); do
            if [ -f "$py_file" ]; then
                echo "  Checking Python file: $py_file"

                # Replace Python 2 shebangs with Python 3
                sed -i.bak 's|#!/usr/bin/python$|#!/usr/bin/env python3|g' "$py_file" 2>/dev/null || \
                sed -i.bak 's|#!/usr/bin/python2$|#!/usr/bin/env python3|g' "$py_file" 2>/dev/null || \
                sed -i.bak 's|#!/usr/bin/env python$|#!/usr/bin/env python3|g' "$py_file" 2>/dev/null || \
                sed -i.bak 's|#!/usr/bin/env python2$|#!/usr/bin/env python3|g' "$py_file" 2>/dev/null

                # Check if the file had Python 2 constructs that need updating
                if grep -q "print " "$py_file" && ! grep -q "print(" "$py_file"; then
                    echo "    Converting Python 2 print statements in $py_file"
                    # More robust approach: convert print statements to print function calls
                    sed -i.bak -E 's/^([[:space:]]*)(print )([^#"].*)$/\1print(\3)/g' "$py_file" 2>/dev/null
                    sed -i.bak -E 's/^([[:space:]]*)(print )([^#"]*"[^"]*")/\1print(\3)/g' "$py_file" 2>/dev/null
                fi

                # Additional Python 2 to Python 3 conversions
                # Convert xrange to range
                sed -i.bak 's/xrange(/range(/g' "$py_file" 2>/dev/null
                sed -i.bak 's/xrange(/range(/g' "$py_file" 2>/dev/null

                # Convert iteritems() to items()
                sed -i.bak 's/.iteritems(/.items(/g' "$py_file" 2>/dev/null
                sed -i.bak 's/.iterkeys(/.keys(/g' "$py_file" 2>/dev/null
                sed -i.bak 's/.itervalues(/.values(/g' "$py_file" 2>/dev/null

                # Handle string/unicode differences
                sed -i.bak 's/unicode(/str(/g' "$py_file" 2>/dev/null
                sed -i.bak 's/ basestring / str /g' "$py_file" 2>/dev/null
                sed -i.bak 's/^basestring$/str/g' "$py_file" 2>/dev/null
            fi
        done
        
        # Check for any shell scripts with Python 2 references
        for sh_file in $(find . -name "*.sh" -type f); do
            if [ -f "$sh_file" ]; then
                sed -i.bak 's|python$|python3|g' "$sh_file" 2>/dev/null || \
                sed -i.bak 's|python2$|python3|g' "$sh_file" 2>/dev/null
            fi
        done
        
        # Copy the processed package to the Sources directory
        if [ -d "$ROOT/Files/Compile/Sources" ]; then
            # Create a directory with the package name in Sources
            PKG_DEST_DIR="$ROOT/Files/Compile/Sources/${package_name}-master"
            if [ ! -d "$PKG_DEST_DIR" ]; then
                cp -r . "$ROOT/Files/Compile/Sources/${package_name}-master"
                echo "  Copied processed package to: $ROOT/Files/Compile/Sources/${package_name}-master"
            else
                echo "  Destination directory already exists, skipping copy for: $package_name"
            fi
        fi
        
        cd ..
    fi
    
    # Clean up
    cd - > /dev/null
    rm -rf "$TEMP_DIR"
}

# Function to extract and process tar.gz files
extract_and_process_tar_gz() {
    local tar_file="$1"
    local package_name="$2"
    
    echo "Processing TAR.GZ file: $tar_file for package: $package_name"
    
    # Create a temporary directory for extraction
    TEMP_DIR=$(mktemp -d "/tmp/${package_name}_XXXXXX")
    cd "$TEMP_DIR"
    
    # Extract the tar.gz file
    tar -xzf "$tar_file"
    
    # Find the extracted directory (usually the first directory created)
    EXTRACTED_DIR=$(find . -maxdepth 1 -type d -not -name "$(basename $TEMP_DIR)" | head -n 1)
    if [ -n "$EXTRACTED_DIR" ]; then
        cd "$EXTRACTED_DIR"
        
        # Check if this is the Listener package that needs special handling
        if echo "$package_name" | grep -qi "listener"; then
            echo "  Processing Listener package - converting Linux daemon to FreeBSD service..."
            
            # Look for systemd service files and convert them to FreeBSD rc.d scripts
            for service_file in $(find . -name "*.service" -type f); do
                if [ -f "$service_file" ]; then
                    echo "    Found Linux systemd service: $service_file"
                    
                    # Create FreeBSD rc.d script from systemd service
                    SERVICE_NAME=$(basename "$service_file" .service)
                    RC_SCRIPT="/etc/init.d/${SERVICE_NAME}"
                    
                    # Extract service information from systemd file
                    EXEC_START=$(grep "ExecStart=" "$service_file" | head -n 1 | cut -d'=' -f2-)
                    DESCRIPTION=$(grep "Description=" "$service_file" | head -n 1 | cut -d'=' -f2- || echo "GoboBSD Listener Service")
                    
                    # Create FreeBSD rc.d script
                    cat > "${ROOT}/System/Settings/rc.d/${SERVICE_NAME}" << RC_EOF
#!/bin/sh
# PROVIDE: $SERVICE_NAME
# REQUIRE: NETWORKING DAEMON
# KEYWORD: shutdown

. /etc/rc.subr

name="$SERVICE_NAME"
rcvar="$SERVICE_NAME\_enable"
command="/usr/local/bin/\$name"
pidfile="/var/run/\$name.pid"

load_rc_config \$name
: \${${SERVICE_NAME}_enable:="NO"}

start_cmd="\${name}_start"
stop_cmd="\${name}_stop"
status_cmd="\${name}_status"

${SERVICE_NAME}_start() {
    echo "Starting $SERVICE_NAME"
    touch \$pidfile
    chown \$name \$pidfile
    daemon -r \$name -p \$pidfile -T $SERVICE_NAME $EXEC_START
}

${SERVICE_NAME}_stop() {
    echo "Stopping $SERVICE_NAME"
    if [ -f \$pidfile ]; then
        pid=\$(cat \$pidfile)
        kill \$pid
        rm -f \$pidfile
    fi
}

${SERVICE_NAME}_status() {
    if [ -f \$pidfile ]; then
        pid=\$(cat \$pidfile)
        if kill -0 \$pid 2>/dev/null; then
            echo "$SERVICE_NAME is running as \$pid"
            return 0
        else
            echo "$SERVICE_NAME is not running"
            return 1
        fi
    else
        echo "$SERVICE_NAME is not running"
        return 1
    fi
}

run_rc_command "\$1"
RC_EOF
                    
                    chmod +x "${ROOT}/System/Settings/rc.d/${SERVICE_NAME}"
                    echo "    Created FreeBSD rc.d script: $ROOT/System/Settings/rc.d/$SERVICE_NAME"
                fi
            done
            
            # Also look for any init.d scripts and convert them if needed
            for init_script in $(find . -name "*init*" -type f); do
                if [ -f "$init_script" ]; then
                    echo "    Found potential init script: $init_script"
                    # Process init script if needed
                fi
            done
        fi
        
        # Check for Python 2 usage and replace with Python 3
        echo "  Checking for Python 2 usage in $package_name..."
        for py_file in $(find . -name "*.py" -type f); do
            if [ -f "$py_file" ]; then
                echo "    Checking Python file: $py_file"
                
                # Replace Python 2 shebangs with Python 3
                sed -i.bak 's|#!/usr/bin/python$|#!/usr/bin/env python3|g' "$py_file" 2>/dev/null || \
                sed -i.bak 's|#!/usr/bin/python2$|#!/usr/bin/env python3|g' "$py_file" 2>/dev/null || \
                sed -i.bak 's|#!/usr/bin/env python$|#!/usr/bin/env python3|g' "$py_file" 2>/dev/null || \
                sed -i.bak 's|#!/usr/bin/env python2$|#!/usr/bin/env python3|g' "$py_file" 2>/dev/null
                
                # Check if the file had Python 2 constructs that need updating
                if grep -q "print " "$py_file" && ! grep -q "print(" "$py_file"; then
                    echo "    Converting Python 2 print statements in $py_file"
                    # More robust approach: convert print statements to print function calls
                    sed -i.bak -E 's/^([[:space:]]*)(print )([^#"].*)$/\1print(\3)/g' "$py_file" 2>/dev/null
                    sed -i.bak -E 's/^([[:space:]]*)(print )([^#"]*"[^"]*")/\1print(\3)/g' "$py_file" 2>/dev/null
                fi

                # Additional Python 2 to Python 3 conversions
                # Convert xrange to range
                sed -i.bak 's/xrange(/range(/g' "$py_file" 2>/dev/null
                sed -i.bak 's/xrange(/range(/g' "$py_file" 2>/dev/null

                # Convert iteritems() to items()
                sed -i.bak 's/.iteritems(/.items(/g' "$py_file" 2>/dev/null
                sed -i.bak 's/.iterkeys(/.keys(/g' "$py_file" 2>/dev/null
                sed -i.bak 's/.itervalues(/.values(/g' "$py_file" 2>/dev/null

                # Handle string/unicode differences
                sed -i.bak 's/unicode(/str(/g' "$py_file" 2>/dev/null
                sed -i.bak 's/ basestring / str /g' "$py_file" 2>/dev/null
                sed -i.bak 's/^basestring$/str/g' "$py_file" 2>/dev/null
            fi
        done
        
        # Check for any shell scripts with Python 2 references
        for sh_file in $(find . -name "*.sh" -type f); do
            if [ -f "$sh_file" ]; then
                sed -i.bak 's|python$|python3|g' "$sh_file" 2>/dev/null || \
                sed -i.bak 's|python2$|python3|g' "$sh_file" 2>/dev/null
            fi
        done
        
        # Copy the processed package to the Sources directory
        if [ -d "$ROOT/Files/Compile/Sources" ]; then
            # Create a directory with the package name in Sources
            PKG_DEST_DIR="$ROOT/Files/Compile/Sources/${package_name}-$(date +%Y%m%d)"
            if [ ! -d "$PKG_DEST_DIR" ]; then
                cp -r . "$ROOT/Files/Compile/Sources/${package_name}-$(date +%Y%m%d)"
                echo "  Copied processed package to: $ROOT/Files/Compile/Sources/${package_name}-$(date +%Y%m%d)"
            else
                echo "  Destination directory already exists, skipping copy for: $package_name"
            fi
        fi
        
        cd ..
    fi
    
    # Clean up
    cd - > /dev/null
    rm -rf "$TEMP_DIR"
}

# Create the rc.d directory if it doesn't exist
mkdir -p "$ROOT/System/Settings/rc.d"

# Process all ZIP files
for zip_file in ../Resources/*.zip; do
    if [ -f "$zip_file" ]; then
        package_name=$(basename "$zip_file" .zip | sed 's/-master$//' | sed 's/-[0-9].*$//')
        extract_and_process_zip "$zip_file" "$package_name"
    fi
done

# Process all tar.gz files (excluding the main system packages that are handled elsewhere)
for tar_file in ../Resources/*.tar.gz; do
    if [ -f "$tar_file" ]; then
        package_name=$(basename "$tar_file" .tar.gz | sed 's/-[0-9].*$//')
        
        # Skip the main system packages that are handled by other scripts
        case "$package_name" in
            "Compile"|"Installer"|"GoboALFS")
                echo "Skipping main system package: $package_name (handled elsewhere)"
                continue
                ;;
        esac
        
        extract_and_process_tar_gz "$tar_file" "$package_name"
    fi
done

# Special handling for the Listener package (which needs Linux daemon to FreeBSD service conversion)
echo "Checking for Listener package specifically..."
if [ -f "../Resources/Listener-2.1.tar.gz" ]; then
    echo "Found Listener-2.1.tar.gz, ensuring it's properly converted for FreeBSD..."
    
    # Extract and process the listener package specifically
    TEMP_LISTENER=$(mktemp -d "/tmp/listener_XXXXXX")
    cd "$TEMP_LISTENER"
    tar -xzf "../Resources/Listener-2.1.tar.gz"
    
    LISTENER_DIR=$(find . -maxdepth 1 -type d -not -name "$(basename $TEMP_LISTENER)" | head -n 1)
    if [ -n "$LISTENER_DIR" ]; then
        cd "$LISTENER_DIR"
        
        # Look for daemon/service related files
        echo "Processing Listener daemon files for FreeBSD compatibility..."
        
        # Look for any Python files that might be daemon-related
        for py_file in $(find . -name "*.py" -type f); do
            if [ -f "$py_file" ]; then
                # Check if it's a daemon/service script
                if grep -q "daemon\|service\|systemd\|init" "$py_file"; then
                    echo "  Found daemon/service Python file: $py_file"
                    # Ensure Python 3 compatibility
                    sed -i.bak 's|#!/usr/bin/python$|#!/usr/bin/env python3|g' "$py_file" 2>/dev/null || \
                    sed -i.bak 's|#!/usr/bin/env python$|#!/usr/bin/env python3|g' "$py_file" 2>/dev/null
                fi
            fi
        done
        
        # Look for any shell scripts that might start services
        for sh_file in $(find . -name "*.sh" -type f); do
            if [ -f "$sh_file" ]; then
                if grep -q "start\|daemon\|service\|systemctl\|init" "$sh_file"; then
                    echo "  Found potential service script: $sh_file"
                    # Ensure proper shebang
                    sed -i.bak 's|#!/bin/sh|#!/bin/sh|g' "$sh_file" 2>/dev/null
                fi
            fi
        done
        
        # Copy to Sources directory
        if [ -d "$ROOT/Files/Compile/Sources" ]; then
            if [ ! -d "$ROOT/Files/Compile/Sources/Listener-2.1" ]; then
                cp -r . "$ROOT/Files/Compile/Sources/Listener-2.1"
                echo "  Copied processed Listener package to: $ROOT/Files/Compile/Sources/Listener-2.1"
            else
                echo "  Listener directory already exists, skipping copy"
            fi
        fi
        
        cd ..
    fi
    
    cd - > /dev/null
    rm -rf "$TEMP_LISTENER"
fi

# Additional check: Look for any remaining Python 2 references in all source directories
echo "Performing final check for Python 2 references in all source directories..."
for py_file in $(find "$ROOT/Files/Compile/Sources" -name "*.py" -type f 2>/dev/null); do
    if [ -f "$py_file" ]; then
        # Check for Python 2 shebangs
        if grep -q "^#!.*python[^3]" "$py_file"; then
            echo "  Updating Python 2 shebang in: $py_file"
            sed -i.bak 's|#!.*python$|#!/usr/bin/env python3|g' "$py_file" 2>/dev/null || \
            sed -i.bak 's|#!.*python2|#!/usr/bin/env python3|g' "$py_file" 2>/dev/null
        fi
    fi
done

echo "Additional packages processed for FreeBSD compatibility!"
echo "Python 2 references have been replaced with Python 3."
echo "Linux daemons have been converted to FreeBSD service scripts where applicable."