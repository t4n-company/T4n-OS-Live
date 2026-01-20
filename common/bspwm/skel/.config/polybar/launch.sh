#!/usr/bin/env sh
# Polybar launcher — anti race, lightweight, bspwm-safe

POLYBAR_DIR="$HOME/.config/polybar"
CONFIG="$POLYBAR_DIR/config.ini"
SYSTEM_INI="$POLYBAR_DIR/system.ini"
DETECTOR="$POLYBAR_DIR/detection.sh"

PRIMARY_BAR="main"
SECONDARY_BAR="secondary"

### 1. Hard gate: tunggu X + monitor siap (ringan & deterministik)
if command -v xrandr >/dev/null 2>&1; then
    until xrandr --listmonitors >/dev/null 2>&1; do
        sleep 0.2
    done
fi

### 2. Pastikan config utama ada
[ -f "$CONFIG" ] || exit 1

### 3. Buat system.ini kalau belum ada
if [ ! -f "$SYSTEM_INI" ]; then
    if [ -x "$DETECTOR" ]; then
        "$DETECTOR" --quick || true
    fi
fi

# Fallback minimal (ANTI FAIL TOTAL)
if [ ! -f "$SYSTEM_INI" ]; then
    cat >"$SYSTEM_INI" <<EOF
[system]
generated=true
EOF
fi

### 4. Kill polybar lama (setelah X siap → aman)
pkill -u "$UID" -x polybar 2>/dev/null

### 5. Detect monitor (single pass, no loop)
MONITORS=""
if command -v xrandr >/dev/null 2>&1; then
    MONITORS=$(xrandr --listmonitors 2>/dev/null | awk 'NR>1 {print $4}')
fi

### 6. Launch polybar
if [ -z "$MONITORS" ]; then
    polybar -c "$CONFIG" --reload "$PRIMARY_BAR" &
    exit 0
fi

PRIMARY=$(printf '%s\n' "$MONITORS" | head -n1)
MONITOR="$PRIMARY" polybar -c "$CONFIG" --reload "$PRIMARY_BAR" &

printf '%s\n' "$MONITORS" | tail -n +2 | while read -r MON; do
    MONITOR="$MON" polybar -c "$CONFIG" --reload "$SECONDARY_BAR" &
done

