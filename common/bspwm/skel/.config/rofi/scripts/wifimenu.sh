#!/bin/bash

# Path ke config rofi
CONFIG="$HOME/.config/rofi/config.rasi"

# Ambil daftar wifi (SSID + signal strength + security)
wifi_list=$(nmcli -f SSID,SIGNAL,SECURITY dev wifi list | sed '1d')

# Ambil SSID yang aktif saat ini
active_ssid=$(nmcli -t -f ACTIVE,SSID dev wifi | grep '^yes' | cut -d: -f2)

# Format menu: SSID + action
menu=""
while IFS= read -r line; do
    ssid=$(echo "$line" | awk '{print $1}')
    if [ "$ssid" == "$active_ssid" ]; then
        menu+="$ssid\tDisconnect\n"
    else
        menu+="$ssid\tConnect\n"
    fi
done <<< "$wifi_list"

# Tampilkan menu dengan rofi (pakai tab separator)
chosen=$(echo -e "$menu" | rofi -dmenu -i -p "WiFi" -config "$CONFIG" | awk '{print $1}')
action=$(echo -e "$menu" | grep "^$chosen" | awk '{print $2}')

# Cancel kalau kosong (ESC)
[ -z "$chosen" ] && exit

# === Kalau Disconnect ===
if [ "$action" == "Disconnect" ]; then
    nmcli con down id "$chosen"
    notify-send "Wi-Fi" "Disconnected from $chosen"
    exit
fi

# === Kalau Connect ===
if [ "$action" == "Connect" ]; then
    security=$(nmcli -f SSID,SECURITY dev wifi list | grep -w "$chosen" | awk '{print $2}')

    if [ "$security" != "--" ]; then
        passwd=$(rofi -dmenu -password -p "Password for $chosen" -config "$CONFIG")
        [ -z "$passwd" ] && exit
        nmcli dev wifi connect "$chosen" password "$passwd"
    else
        nmcli dev wifi connect "$chosen"
    fi
fi
