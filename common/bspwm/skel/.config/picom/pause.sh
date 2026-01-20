#!/bin/bash

while true; do
    # Cek apakah ada window aktif
    WINID=$(xprop -root _NET_ACTIVE_WINDOW 2>/dev/null | awk -F' ' '{print $5}')
    if [[ -n "$WINID" && "$WINID" != "0x0" ]]; then
        # Cek apakah window aktif dalam mode fullscreen
        if xprop -id "$WINID" 2>/dev/null | grep -q "_NET_WM_STATE_FULLSCREEN"; then
            pkill -x picom
        else
            if ! pgrep -x picom >/dev/null; then
                picom --config "$HOME/.config/picom/picom.conf" &
            fi
        fi
    fi
    sleep 3
done
