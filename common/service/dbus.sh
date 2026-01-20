#!/bin/bash

# setup_dbus: Setup D-Bus system and session bus
# Parameters:
#   $1 - INCLUDEDIR (root directory for including files)
#   $2 - ARCH (architecture)
setup_dbus() {
    # Validasi parameter
    local INCLUDEDIR="${1}"
    local ARCH="${2}"
    
    if [ -z "$INCLUDEDIR" ] || [ -z "$ARCH" ]; then
        echo "ERROR: Missing parameters for setup_dbus" >&2
        return 1
    fi
    
    # Langsung tambahkan ke variabel yang ada (dari parent scope)
    PKGS="$PKGS dbus"
    SERVICES="$SERVICES dbus"
    
    # Sisa kode setup...
    mkdir -p "$INCLUDEDIR"/etc/dbus-1
    # ... (salin sisa kode dari versi yang sudah diperbaiki)
    
    info_msg "D-Bus setup completed for $ARCH"
}
