#!/bin/bash

# Path ke config rofi lo
CONFIG="$HOME/.config/rofi/config.rasi"

# Opsi menu
options="  Lock\n  Suspend\n  Restart\n  Shutdown\n  Log Out"

# Tampilkan rofi
chosen="$(echo -e "$options" | rofi -dmenu -i -p "Power Menu" -config "$CONFIG")"

case $chosen in
    "  Lock")
        # Sesuaikan lockscreen yang lo pakai
        i3lock -c 000000
        ;;
    "  Suspend")
        systemctl suspend
        ;;
    "  Restart")
        systemctl reboot
        ;;
    "  Shutdown")
        systemctl poweroff
        ;;
    "  Log Out")
        i3-msg exit
        ;;
esac
