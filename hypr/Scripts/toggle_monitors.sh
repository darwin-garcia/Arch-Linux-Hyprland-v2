#!/bin/bash
set -u

for cmd in hyprctl jq notify-send flock; do
    command -v "$cmd" >/dev/null 2>&1 || exit 1
done

LOCKFILE="${XDG_RUNTIME_DIR:-/tmp}/hypr_monitor.lock"
exec 200>"$LOCKFILE"
flock -n 200 || exit 0

STATE_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/hypr_monitor_state"
mkdir -p "$(dirname "$STATE_FILE")"

MAIN_MONITOR=$(hyprctl monitors -j all | jq -r '.[] | select(.name | startswith("eDP")) | .name' | head -n1)
[ -z "$MAIN_MONITOR" ] && MAIN_MONITOR="eDP-1"

EXTERNAL_MONITOR=$(hyprctl monitors -j all | jq -r '.[] | select(.name | startswith("eDP") | not) | .name' | head -n1)

if [ -z "$EXTERNAL_MONITOR" ]; then
    for port in /sys/class/drm/card*-*; do
        [ -e "$port/status" ] || continue
        if [ "$(cat "$port/status")" = "connected" ]; then
            PORT_NAME=$(basename "$port" | sed 's/card[0-9]-//')
            [[ "$PORT_NAME" != eDP* ]] && EXTERNAL_MONITOR="$PORT_NAME" && break
        fi
    done
fi

if [ -z "$EXTERNAL_MONITOR" ] || [ "$EXTERNAL_MONITOR" = "$MAIN_MONITOR" ]; then
    notify-send "Hyprland" "No hay ninguna pantalla secundaria detectada."
    exit 0
fi

[ -f "$STATE_FILE" ] || echo "extend" > "$STATE_FILE"
CURRENT_STATE=$(cat "$STATE_FILE")

case "$CURRENT_STATE" in

    extend)
        if hyprctl keyword monitor "$EXTERNAL_MONITOR, preferred, auto, 1.25, mirror, $MAIN_MONITOR"; then
            notify-send "Pantallas" "Modo: Duplicar (Espejo)"
            echo "mirror" > "$STATE_FILE"
        fi
        ;;

    mirror)
        if hyprctl keyword monitor "$EXTERNAL_MONITOR, disable"; then
            notify-send "Pantallas" "Modo: Solo pantalla principal"
            echo "single_internal" > "$STATE_FILE"
        fi
        ;;

    single_internal)

        hyprctl keyword monitor "$MAIN_MONITOR, disable"

        if hyprctl keyword monitor "$EXTERNAL_MONITOR, preferred, auto, 1.25"; then
            notify-send "Pantallas" "Modo: Solo monitor externo"
            echo "single_external" > "$STATE_FILE"
        pl
        ;;

    single_external)

        hyprctl keyword monitor "$MAIN_MONITOR, preferred, auto, 1"

        if hyprctl keyword monitor "$EXTERNAL_MONITOR, preferred, auto, 1"; then
            notify-send "Pantallas" "Modo: Ampliar escritorio"
            echo "extend" > "$STATE_FILE"
        fi
        ;;

    *)
        echo "extend" > "$STATE_FILE"
        ;;
esacppp
