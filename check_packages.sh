#!/bin/sh

# Get the list of packages from get_resources.sh
PACKAGES=$(cd /home/xaturing/Gobobsd-15.0 && grep -E 'download_file.*tar|download_file.*tgz|download_file.*bz2|Scripts-.*tar|Compile-.*tar|doas-portable' get_resources.sh | grep -oE '[a-zA-Z0-9._-]+\.(tar\.gz|tar\.xz|tar\.bz2|tgz)' | sort | uniq)

# Get the list of packages from fetch commands
FETCH_PACKAGES=$(cd /home/xaturing/Gobobsd-15.0 && grep -E 'fetch -o' get_resources.sh | grep -oE '[a-zA-Z0-9._-]+\.(tar\.gz|tar\.xz|tar\.bz2|tgz|tbz)' | sort | uniq)

# Combine both lists
ALL_PACKAGES=$(echo "$PACKAGES" "$FETCH_PACKAGES" | sort | uniq)

# Get the list of available packages in FreeBSD archive
FREEBSD_PACKAGES=$(curl -s http://ftp-archive.freebsd.org/pub/FreeBSD-Archive/ports/amd64/packages-9.2-release/All/ | grep -oE 'href="[^"]*\.tbz"' | sed 's/href="//' | sed 's/\.tbz"//' | sort)

echo "Checking which packages from get_resources.sh are available in FreeBSD archive..."
echo "==============================================================================="

MATCHES=0
TOTAL=0

for pkg in $ALL_PACKAGES; do
    TOTAL=$((TOTAL + 1))
    # Remove extension to get base name for comparison
    base_name=$(echo "$pkg" | sed 's/\.\(tar\.gz\|tar\.xz\|tar\.bz2\|tgz\)$//')
    
    # Check if any FreeBSD package starts with this base name (case-insensitive)
    found=0
    for freebsd_pkg in $FREEBSD_PACKAGES; do
        # Convert to lowercase for comparison
        lower_freebsd=$(echo "$freebsd_pkg" | tr '[:upper:]' '[:lower:]')
        lower_base=$(echo "$base_name" | tr '[:upper:]' '[:lower:]')
        
        # Check if the FreeBSD package starts with the base name (with version number)
        if echo "$lower_freebsd" | grep -q "^$(echo "$lower_base" | sed 's/[.-][0-9].*//')"; then
            # More specific check: see if the base name is at the beginning
            if [ "${lower_freebsd#"$lower_base"}" != "$lower_freebsd" ]; then
                # Exact match or starts with the name
                echo "FOUND: $pkg -> $freebsd_pkg.tbz"
                MATCHES=$((MATCHES + 1))
                found=1
                break
            elif echo "$lower_freebsd" | grep -qi "^$(echo "$lower_base" | sed 's/-[0-9].*//')"; then
                # Partial match - package name without version matches
                echo "POSSIBLE MATCH: $pkg -> $freebsd_pkg.tbz"
                MATCHES=$((MATCHES + 1))
                found=1
                break
            fi
        fi
    done
    
    if [ $found -eq 0 ]; then
        echo "NOT FOUND: $pkg"
    fi
done

echo ""
echo "Summary:"
echo "Total packages in get_resources.sh: $TOTAL"
echo "Available in FreeBSD archive: $MATCHES"
echo "Not available in FreeBSD archive: $((TOTAL - MATCHES))"