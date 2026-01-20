#!/bin/bash

# setup_polkitd: Setup PolicyKit daemon
# Parameters:
#   $1 - INCLUDEDIR (root directory for including files)
#   $2 - ARCH (architecture)
setup_polkitd() {
    # Validasi parameter dengan nilai default
    local INCLUDEDIR="${1:-}"
    local ARCH="${2:-}"
    
    # Validasi parameter wajib
    if [ -z "$INCLUDEDIR" ]; then
        echo "ERROR: setup_polkitd: INCLUDEDIR parameter is required" >&2
        return 1
    fi
    
    if [ -z "$ARCH" ]; then
        echo "ERROR: setup_polkitd: ARCH parameter is required" >&2
        return 1
    fi
    
    # Pastikan PKGS dan SERVICES ada
    if [ -z "${PKGS:-}" ]; then
        local PKGS=""
    fi
    
    if [ -z "${SERVICES:-}" ]; then
        local SERVICES=""
    fi
    
    # Add polkit package
    PKGS="$PKGS polkit"
    
    # Add polkitd service
    SERVICES="$SERVICES polkitd"
    
    # Create polkit configuration directory
    mkdir -p "$INCLUDEDIR"/etc/polkit-1/rules.d
    mkdir -p "$INCLUDEDIR"/usr/share/polkit-1/rules.d
    
    # Create basic polkit rules for common actions
    cat > "$INCLUDEDIR"/etc/polkit-1/rules.d/50-default.rules << EOF
polkit.addRule(function(action, subject) {
    // Allow users in wheel group to perform administrative tasks
    if (subject.isInGroup("wheel")) {
        return polkit.Result.YES;
    }
    
    // Allow network group to manage network connections
    if (action.id.indexOf("org.freedesktop.NetworkManager.") == 0 && 
        subject.isInGroup("network")) {
        return polkit.Result.YES;
    }
    
    // Allow storage group to mount drives
    if (action.id.indexOf("org.freedesktop.udisks2.") == 0 && 
        subject.isInGroup("storage")) {
        return polkit.Result.YES;
    }
    
    // Allow power management for users
    if (action.id.indexOf("org.freedesktop.login1.") == 0 && 
        subject.isInGroup("power")) {
        return polkit.Result.YES;
    }
});
EOF
    
    # Create polkit agent for authentication
    mkdir -p "$INCLUDEDIR"/etc/xdg/autostart
    cat > "$INCLUDEDIR"/etc/xdg/autostart/polkit-gnome-authentication-agent-1.desktop << EOF
[Desktop Entry]
Type=Application
Name=PolicyKit Authentication Agent
Exec=/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
OnlyShowIn=GNOME;XFCE;KDE;
NoDisplay=true
EOF
    
    # Create polkitd user and groups
    mkdir -p "$INCLUDEDIR"/usr/lib/sysusers.d
    cat > "$INCLUDEDIR"/usr/lib/sysusers.d/polkit.conf << EOF
# Polkit system user/group
u polkitd 102 "PolicyKit daemon"
g polkitd 102

# Administrative groups
g wheel - -
g network - -
g storage - -
g power - -
EOF
    
    # Add polkitd user to passwd and group files
    if [ -f "$INCLUDEDIR"/etc/passwd ]; then
        grep -q "^polkitd:" "$INCLUDEDIR"/etc/passwd || echo "polkitd:x:102:102:PolicyKit daemon:/var/lib/polkit:/bin/false" >> "$INCLUDEDIR"/etc/passwd
    fi
    
    if [ -f "$INCLUDEDIR"/etc/group ]; then
        # Create polkitd group
        grep -q "^polkitd:" "$INCLUDEDIR"/etc/group || echo "polkitd:x:102:" >> "$INCLUDEDIR"/etc/group
        
        # Create administrative groups
        for group in wheel network storage power; do
            if ! grep -q "^$group:" "$INCLUDEDIR"/etc/group; then
                case $group in
                    wheel) echo "wheel:x:10:" >> "$INCLUDEDIR"/etc/group ;;
                    network) echo "network:x:998:" >> "$INCLUDEDIR"/etc/group ;;
                    storage) echo "storage:x:6:" >> "$INCLUDEDIR"/etc/group ;;
                    power) echo "power:x:997:" >> "$INCLUDEDIR"/etc/group ;;
                esac
            fi
        done
        
        # Add default users to wheel group
        for user in root liveuser; do
            if grep -q "^$user:" "$INCLUDEDIR"/etc/passwd; then
                if ! grep -q "^wheel:.*$user" "$INCLUDEDIR"/etc/group; then
                    sed -i "/^wheel:/s/$/,$user/" "$INCLUDEDIR"/etc/group
                    sed -i "/^wheel:/s/,$//" "$INCLUDEDIR"/etc/group
                fi
            fi
        done
    fi
    
    # Create polkitd configuration
    mkdir -p "$INCLUDEDIR"/etc/polkit-1/localauthority.conf.d
    cat > "$INCLUDEDIR"/etc/polkit-1/localauthority.conf.d/50-localauthority.conf << EOF
[Configuration]
AdminIdentities=unix-group:wheel
EOF
    
    # Create runtime directory for polkitd
    mkdir -p "$INCLUDEDIR"/var/lib/polkit-1
    chown polkitd:polkitd "$INCLUDEDIR"/var/lib/polkit-1 2>/dev/null || true
    chmod 700 "$INCLUDEDIR"/var/lib/polkit-1
    
    # Create local authority directory
    mkdir -p "$INCLUDEDIR"/var/lib/polkit-1/localauthority
    chown polkitd:polkitd "$INCLUDEDIR"/var/lib/polkit-1/localauthority 2>/dev/null || true
    chmod 700 "$INCLUDEDIR"/var/lib/polkit-1/localauthority
    
    # Return updated PKGS and SERVICES
    echo "$PKGS"
    echo "$SERVICES"
}
