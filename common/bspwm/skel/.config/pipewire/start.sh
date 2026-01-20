#!/bin/sh
# Start PipeWire services untuk Void Linux

# Kill existing audio services
pkill -9 pipewire 2>/dev/null
pkill -9 wireplumber 2>/dev/null
pkill -9 pipewire-media-session 2>/dev/null
pkill -9 pulseaudio 2>/dev/null

# Set runtime directory untuk PipeWire
export XDG_RUNTIME_DIR=/run/user/$(id -u)
export PIPEWIRE_RUNTIME_DIR=$XDG_RUNTIME_DIR
mkdir -p $XDG_RUNTIME_DIR 2>/dev/null

# Start PipeWire (tanpa pipewire-pulse karena tidak ada di Void)
pipewire &
sleep 2

# Start WirePlumber
wireplumber &
sleep 1

echo "PipeWire started for Void Linux"
echo "Note: pipewire-pulse not needed - PulseAudio compatibility built-in"
