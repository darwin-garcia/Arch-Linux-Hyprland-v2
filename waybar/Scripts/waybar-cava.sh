#!/usr/bin/env bash

bars=("▁" "▂" "▃" "▄" "▅" "▆" "▇" "█")

CONFIG="$(mktemp)"

cat > "$CONFIG" <<EOF
[general]
bars = 12
framerate = 60
autosens = 1
sensitivity = 80

[input]
# pipewire | pulse | alsa
method = pulse
source = auto

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7

[smoothing]
integral = 70
EOF

cleanup() {
    rm -f "$CONFIG"
}

trap cleanup EXIT
# Ignorar SIGPIPE a nivel del shell para que el pipeline no muera
# cuando Waybar deja de leer (reload, reinicio, etc.)
trap '' PIPE

run_cava() {
    stdbuf -oL cava -p "$CONFIG" 2>/dev/null |
    while IFS= read -r line; do
        output=""

        IFS=';' read -ra vals <<< "$line"

        for v in "${vals[@]}"; do
            [[ "$v" =~ ^[0-7]$ ]] || continue
            output+="${bars[$v]}"
        done

        # Si printf falla (pipe roto hacia Waybar), salir del subshell
        # limpiamente para que el loop externo reinicie cava
        printf '{"text":"%s"}\n' "$output" 2>/dev/null || exit 0
    done
}

# Auto-restart: si cava muere (SIGPIPE, audio device cambia, suspend, etc.)
# el módulo se recupera solo sin intervención del usuario
while true; do
    run_cava
    sleep 1
done