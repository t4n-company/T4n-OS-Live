#!/bin/bash

# setup_pipewire: Setup PipeWire audio system
# Parameters:
#   $1 - INCLUDEDIR (root directory for including files)
#   $2 - ARCH (architecture)
setup_pipewire() {
    # Validasi parameter dengan nilai default
    local INCLUDEDIR="${1:-}"
    local ARCH="${2:-}"
    
    # Validasi parameter wajib
    if [ -z "$INCLUDEDIR" ]; then
        echo "ERROR: setup_pipewire: INCLUDEDIR parameter is required" >&2
        return 1
    fi
    
    if [ -z "$ARCH" ]; then
        echo "ERROR: setup_pipewire: ARCH parameter is required" >&2
        return 1
    fi
    
    # Pastikan PKGS dan SERVICES ada
    if [ -z "${PKGS:-}" ]; then
        local PKGS=""
    fi
    
    if [ -z "${SERVICES:-}" ]; then
        local SERVICES=""
    fi
    
    # Add pipewire packages
    PKGS="$PKGS pipewire alsa-pipewire wireplumber"
    
    case "$ARCH" in
        asahi*)
            PKGS="$PKGS asahi-audio"
            SERVICES="$SERVICES speakersafetyd"
            ;;
    esac
    
    # Setup autostart for pipewire
    mkdir -p "$INCLUDEDIR"/etc/xdg/autostart
    ln -sf /usr/share/applications/pipewire.desktop "$INCLUDEDIR"/etc/xdg/autostart/
    
    # Setup pipewire configuration
    mkdir -p "$INCLUDEDIR"/etc/pipewire/pipewire.conf.d
    
    # WirePlumber configuration
    if [ -f /usr/share/examples/wireplumber/10-wireplumber.conf ]; then
        ln -sf /usr/share/examples/wireplumber/10-wireplumber.conf "$INCLUDEDIR"/etc/pipewire/pipewire.conf.d/
    fi
    
    # PipeWire PulseAudio compatibility
    if [ -f /usr/share/examples/pipewire/20-pipewire-pulse.conf ]; then
        ln -sf /usr/share/examples/pipewire/20-pipewire-pulse.conf "$INCLUDEDIR"/etc/pipewire/pipewire.conf.d/
    fi
    
    # Setup ALSA configuration
    mkdir -p "$INCLUDEDIR"/etc/alsa/conf.d
    ln -sf /usr/share/alsa/alsa.conf.d/50-pipewire.conf "$INCLUDEDIR"/etc/alsa/conf.d
    ln -sf /usr/share/alsa/alsa.conf.d/99-pipewire-default.conf "$INCLUDEDIR"/etc/alsa/conf.d
    
    # Create pipewire user/group entries
    mkdir -p "$INCLUDEDIR"/usr/lib/sysusers.d
    cat > "$INCLUDEDIR"/usr/lib/sysusers.d/pipewire.conf << EOF
# PipeWire system user/group
u pipewire 63 "PipeWire System User"
g pipewire 63
EOF
    
    # Add pipewire user to passwd and group files
    if [ -f "$INCLUDEDIR"/etc/passwd ]; then
        grep -q "^pipewire:" "$INCLUDEDIR"/etc/passwd || echo "pipewire:x:63:63:PipeWire System User:/var/run/pipewire:/bin/false" >> "$INCLUDEDIR"/etc/passwd
    fi
    
    if [ -f "$INCLUDEDIR"/etc/group ]; then
        # Ensure pipewire group exists
        grep -q "^pipewire:" "$INCLUDEDIR"/etc/group || echo "pipewire:x:63:" >> "$INCLUDEDIR"/etc/group
        
        # Add pipewire user to audio group
        if grep -q "^audio:" "$INCLUDEDIR"/etc/group; then
            sed -i '/^audio:/s/$/,pipewire/' "$INCLUDEDIR"/etc/group
            sed -i '/^audio:/s/,$//' "$INCLUDEDIR"/etc/group
        else
            echo "audio:x:29:pipewire" >> "$INCLUDEDIR"/etc/group
        fi
    fi
    
    # Create runtime directories for pipewire
    mkdir -p "$INCLUDEDIR"/var/run/pipewire
    chown pipewire:pipewire "$INCLUDEDIR"/var/run/pipewire 2>/dev/null || true
    chmod 755 "$INCLUDEDIR"/var/run/pipewire
    
    # Create configuration directory
    mkdir -p "$INCLUDEDIR"/etc/pipewire
    chown pipewire:pipewire "$INCLUDEDIR"/etc/pipewire 2>/dev/null || true
    chmod 755 "$INCLUDEDIR"/etc/pipewire
    
    # Return updated PKGS and SERVICES
    echo "$PKGS"
    echo "$SERVICES"
}
