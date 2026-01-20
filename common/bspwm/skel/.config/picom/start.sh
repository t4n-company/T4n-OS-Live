#!/bin/bash

# Matikan picom jika berjalan
killall -q picom

# Pastikan benar-benar mati
while pgrep -u $UID -x picom >/dev/null; do sleep 1; done

# Start picom dengan config
picom --config "$HOME/.config/picom/picom.conf" &

exit 0
