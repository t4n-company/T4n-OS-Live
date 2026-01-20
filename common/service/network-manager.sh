#!/bin/bash

setup_nm() {
    local INCLUDEDIR="${1}"
    local ARCH="${2}"
    
    if [ -z "$INCLUDEDIR" ] || [ -z "$ARCH" ]; then
        echo "ERROR: Missing parameters for setup_nm" >&2
        return 1
    fi
    
    PKGS="$PKGS NetworkManager"
    # ... (salin sisa kode)
}
