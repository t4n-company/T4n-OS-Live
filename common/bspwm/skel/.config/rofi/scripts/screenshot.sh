#!/bin/bash

#!/bin/bash

CONFIG="$HOME/.config/rofi/config.rasi"
DIR="$HOME/Pictures"
DATE=$(date +'%Y-%m-%d_%H-%M-%S')
FILE="$DIR/screenshot_$DATE.png"

MENU="  Fullscreen\n⛶  Window\n⿻  Area\n⌛  Delay 5s\n  Clipboard"

CHOSEN=$(echo -e "$MENU" | rofi -dmenu -i -p "Screenshot" -config "$CONFIG")

case "$CHOSEN" in
    "  Fullscreen")
        xfce4-screenshooter -f -s "$FILE"
        notify-send "📸 Screenshot" "Fullscreen saved → $FILE"
        ;;
    "⛶  Window")
        xfce4-screenshooter -w -s "$FILE"
        notify-send "📸 Screenshot" "Window saved → $FILE"
        ;;
    "⿻  Area")
        xfce4-screenshooter -r -s "$FILE"
        notify-send "📸 Screenshot" "Area saved → $FILE"
        ;;
    "⌛  Delay 5s")
        xfce4-screenshooter -d 5 -f -s "$FILE"
        notify-send "📸 Screenshot" "Fullscreen (Delay 5s) saved → $FILE"
        ;;
    "  Clipboard")
        xfce4-screenshooter -f -s "$FILE"
        xclip -selection clipboard -t image/png -i "$FILE"
        notify-send "📸 Screenshot" "Fullscreen copied to clipboard ✅"
        ;;
esac

