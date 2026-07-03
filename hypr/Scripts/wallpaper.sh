#!/bin/bash

WALLDIR="$HOME/.config/hypr/Wallpapers"

TRANSITIONS=(
    grow
    fade
    wipe
    outer
)

while true; do

    IMG=$(find "$WALLDIR" -type f | shuf -n 1)

    EFFECT=${TRANSITIONS[$RANDOM % ${#TRANSITIONS[@]}]}

    awww img "$IMG" \
        --transition-type "$EFFECT" \
        --transition-duration 1

    sleep 3600

done