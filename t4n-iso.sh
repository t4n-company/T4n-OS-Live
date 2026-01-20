#!/bin/bash

set -eu

. ./lib.sh

# Source service setup functions
. ./common/service/dbus.sh
. ./common/service/network-manager.sh
. ./common/service/pipewire.sh
. ./common/service/polkitd.sh

PROGNAME=$(basename "$0")
ARCH=$(uname -m)
IMAGES="base"
TRIPLET=
REPO=
DATE=$(date -u +%Y%m%d)

usage() {
	cat <<-EOH
	Usage: $PROGNAME [options ...] [-- t4n-live options ...]

	Wrapper script around t4n-live.sh for several standard flavors of live images.
	Adds void-installer and other helpful utilities to the generated images.

	OPTIONS
	 -a <arch>     Set architecture (or platform) in the image
	 -b <variant>  One of base, base-wayland, base-x11, server, bspwm, kde, river,
                   xfce or xfce-wayland (default: base). May be specified multiple times
                   to build multiple variants
	 -d <date>     Override the datestamp on the generated image (YYYYMMDD format)
	 -t <arch-date-variant>
	               Equivalent to setting -a, -b, and -d
	 -r <repo>     Use this XBPS repository. May be specified multiple times
	 -h            Show this help and exit
	 -V            Show version and exit

	Other options can be passed directly to t4n-live.sh by specifying them after the --.
	See t4n-live.sh -h for more details.
	EOH
}

while getopts "a:b:d:t:hr:V" opt; do
case $opt in
    a) ARCH="$OPTARG";;
    b) IMAGES="$OPTARG";;
    d) DATE="$OPTARG";;
    r) REPO="-r $OPTARG $REPO";;
    t) TRIPLET="$OPTARG";;
    V) version; exit 0;;
    h) usage; exit 0;;
    *) usage >&2; exit 1;;
esac
done
shift $((OPTIND - 1))

INCLUDEDIR=$(mktemp -d)
trap "cleanup" INT TERM

info_msg() {
    echo "[INFO] $1"
}

cleanup() {
    rm -rf "$INCLUDEDIR"
}

include_installer() {
    if [ -x installer.sh ]; then
        MKLIVE_VERSION="$(PROGNAME='' version)"
        installer=$(mktemp)
        sed "s/@@MKLIVE_VERSION@@/${MKLIVE_VERSION}/" installer.sh > "$installer"
        install -Dm755 "$installer" "$INCLUDEDIR"/usr/bin/void-installer
        rm "$installer"
    else
        echo installer.sh not found >&2
        exit 1
    fi
}

#include_installer_py()

include_cli() {
    mkdir -p "$INCLUDEDIR"/etc
    mkdir -p "$INCLUDEDIR"/etc/default
    mkdir -p "$INCLUDEDIR"/etc/runit
    mkdir -p "$INCLUDEDIR"/etc/skel
    mkdir -p "$INCLUDEDIR"/etc/skel/.config
    mkdir -p "$INCLUDEDIR"/etc/X11
    mkdir -p "$INCLUDEDIR"/etc/X11/xorg.conf.d
    mkdir -p "$INCLUDEDIR"/usr
    mkdir -p "$INCLUDEDIR"/usr/share
    mkdir -p "$INCLUDEDIR"/usr/share/fonts

    cp ./common/script/resolv.conf "$INCLUDEDIR"/etc/
    cat > "$INCLUDEDIR"/etc/resolv.conf << EOF
nameserver 1.1.1.1
nameserver 8.8.8.8
EOF

    cp ./common/script/os-release "$INCLUDEDIR"/etc/
    cp ./common/script/grub "$INCLUDEDIR"/etc/default/
    cp ./common/script/.bashrc "$INCLUDEDIR"/etc/skel/

    cp -r ./common/base-x11/xorg.conf.d "$INCLUDEDIR"/etc/X11/xorg.conf.d/
    cp -r ./common/script/runit/* "$INCLUDEDIR"/etc/runit/
}
#include_gui()

#include_vur-helper()

#include_base-x11()
#include_base-wayland()
#include_server()
include_bspwm() {
    PKGS="$PKGS bspwm sxhkd polybar dunst rofi feh alacritty picom Thunar brightnessctl pavucontrol mousepad lm_sensors xdg_user_dirs"
    cp -r ./common/bspwm/skel/.config/* "$INCLUDEDIR"/etc/skel/.config/
    cp -r ./common/bspwm/skel/.fonts/* "$INCLUDEDIR"/usr/share/fonts/
}
#include_kde()
#include_river()
#include_xfce()
#include_xfce-wayland()

build_variant() {
    variant="$1"
    shift
    IMG=t4n-os-live-${ARCH}-${DATE}-${variant}.iso

    # el-cheapo installer is unsupported on arm because arm doesn't install a kernel by default
    # and to work around that would add too much complexity to it
    # thus everyone should just do a chroot install anyways
    WANT_INSTALLER=no
    case "$ARCH" in
        x86_64*|i686*)
            GRUB_PKGS="grub-i386-efi grub-x86_64-efi"
            GFX_PKGS="xorg-video-drivers xf86-video-intel xf86-video-amdgpu xf86-video-ati"
            GFX_WL_PKGS="mesa-dri"
            WANT_INSTALLER=yes
            TARGET_ARCH="$ARCH"
            ;;
        aarch64*)
            GRUB_PKGS="grub-arm64-efi"
            GFX_PKGS="xorg-video-drivers"
            GFX_WL_PKGS="mesa-dri"
            TARGET_ARCH="$ARCH"
            ;;
        asahi*)
            GRUB_PKGS="asahi-base asahi-scripts grub-arm64-efi"
            GFX_PKGS="mesa-asahi-dri"
            GFX_WL_PKGS="mesa-asahi-dri"
            KERNEL_PKG="linux-asahi"
            TARGET_ARCH="aarch64${ARCH#asahi}"
            if [ "$variant" = xfce ]; then
                info_msg "xfce is not supported on asahi, switching to xfce-wayland"
                variant="xfce-wayland"
            fi
            ;;
    esac

    A11Y_PKGS="espeakup void-live-audio brltty"
    PKGS="dialog cryptsetup lvm2 mdadm void-docs-browse xtools-minimal xmirror chrony tmux $A11Y_PKGS $GRUB_PKGS"
    FILE_PKGS="tar xz gzip zstd zip unzip 7zip p7zip"
    FONTS="font-misc-misc terminus-font dejavu-fonts-ttf"
    FONTS_WM="font-firacode font-iosevka nerd-fonts-symbols-ttf"
    WAYLAND_PKGS="$GFX_WL_PKGS $FONTS orca"
    XORG_PKGS="$GFX_PKGS $FONTS xorg-fonts xorg-server xorg-apps xorg-minimal xorg-input-drivers setxkbmap xauth orca"
    SERVICES="sshd chronyd"

    LIGHTDM_SESSION=''
    BSPWM=''

    case $variant in
        base)
            PKGS="$PKGS $XORG_PKGS $FILE_PKGS tree bat eza exa nano elogind"
            CLI=yes

            SERVICES="$SERVICES dhcpcd wpa_supplicant acpid elogind"
        ;;
        #base-wayland)
        #    SERVICES="$SERVICES dhcpcd wpa_supplicant acpid"
        #;;
        base-x11)
            PKGS="$PKGS $XORG_PKGS $FILE_PKGS tree bat eza exa nano network-manager-applet"
            CLI=yes

            SERVICES="$SERVICES dbus acpid"
        ;;
        #server)
        #    SERVICES="$SERVICES dhcpcd wpa_supplicant acpid"
        #;;
        bspwm)
            PKGS="$PKGS $XORG_PKGS $FILE_PKGS $FONTS_WM tree bat eza exa nano elogind NetworkManager lightdm lightdm-gtk-greeter gvfs-afc gvfs-mtp gvfs-smb udisks2 firefox"
            CLI=yes
            BSPWM='yes'

            SERVICES="$SERVICES dbus lightdm NetworkManager polkitd elogind"
            LIGHTDM_SESSION='bspwm'
        ;;
        #kde)
        #    SERVICES="$SERVICES dhcpcd wpa_supplicant acpid"
        #;;
        #river)
        #    SERVICES="$SERVICES dhcpcd wpa_supplicant acpid"
        #;;
        #xfce*)
        #    PKGS="$PKGS $XORG_PKGS lightdm lightdm-gtk-greeter xfce4 gnome-themes-standard gnome-keyring network-manager-applet gvfs-afc gvfs-mtp gvfs-smb udisks2 firefox xfce4-pulseaudio-plugin"
        #    SERVICES="$SERVICES dbus lightdm NetworkManager polkitd"
        #    LIGHTDM_SESSION=xfce

        #    if [ "$variant" == "xfce-wayland" ]; then
        #        PKGS="$PKGS $WAYLAND_PKGS labwc"
        #        LIGHTDM_SESSION="xfce-wayland"
        #    fi
        #;;
        *)
            >&2 echo "Unknown variant $variant"
            exit 1
        ;;
    esac

    if [ -n "$LIGHTDM_SESSION" ]; then
        mkdir -p "$INCLUDEDIR"/etc/lightdm
        echo "$LIGHTDM_SESSION" > "$INCLUDEDIR"/etc/lightdm/.session
        # needed to show the keyboard layout menu on the login screen
        cat <<- EOF > "$INCLUDEDIR"/etc/lightdm/lightdm-gtk-greeter.conf
[greeter]
indicators = ~host;~spacer;~clock;~spacer;~layout;~session;~a11y;~power
EOF
    fi

    if [ "$CLI" = yes ]; then
        include_cli
    fi

    if [ "$BSPWM" = 'yes' ]; then
        include_bspwm
    fi

    if [ "$WANT_INSTALLER" = yes ]; then
        include_installer
    else
        mkdir -p "$INCLUDEDIR"/usr/bin
        printf "#!/bin/sh\necho 'void-installer is not supported on this live image'\n" > "$INCLUDEDIR"/usr/bin/void-installer
        chmod 755 "$INCLUDEDIR"/usr/bin/void-installer
    fi

    case "$variant" in
        base|server)
            ;;
        base-x11|base-wayland)
            setup_dbus "$INCLUDEDIR" "$ARCH"
            setup_nm "$INCLUDEDIR" "$ARCH"
            ;;
        *)
            setup_dbus "$INCLUDEDIR" "$ARCH"
            setup_nm "$INCLUDEDIR" "$ARCH"
            setup_pipewire "$INCLUDEDIR" "$ARCH"
            setup_polkitd "$INCLUDEDIR" "$ARCH"
            ;;
    esac

    ./t4n-live.sh -a "$TARGET_ARCH" -o "$IMG" -p "$PKGS" -S "$SERVICES" -I "$INCLUDEDIR" \
        ${KERNEL_PKG:+-v $KERNEL_PKG} ${REPO} "$@"

	cleanup
}

if [ ! -x t4n-live.sh ]; then
    echo t4n-live.sh not found >&2
    exit 1
fi

if [ -n "$TRIPLET" ]; then
    IFS=: read -r ARCH DATE VARIANT _ < <( echo "$TRIPLET" | sed -Ee 's/^(.+)-([0-9rc]+)-(.+)$/\1:\2:\3/' )
    build_variant "$VARIANT" "$@"
else
    for image in $IMAGES; do
        build_variant "$image" "$@"
    done
fi
