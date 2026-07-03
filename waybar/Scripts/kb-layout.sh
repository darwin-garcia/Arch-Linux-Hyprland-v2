#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
#  keyboard_layout.sh  –  Muestra y cambia el layout por teclado
#
#  Uso:
#    keyboard_layout.sh            → imprime JSON para waybar
#    keyboard_layout.sh switch     → alterna entre us / es en el teclado activo
#    keyboard_layout.sh switch-laptop   → alterna solo el teclado interno
#    keyboard_layout.sh switch-external → alterna solo el teclado externo
#
#  Para identificar los nombres exactos de tus dispositivos ejecuta:
#    hyprctl devices | grep -A2 "Keyboard"
#  y reemplaza las variables LAPTOP_KB y EXTERNAL_KB abajo.
# ─────────────────────────────────────────────────────────────────────────────

# ── CONFIGURA AQUÍ los nombres de tus teclados ──────────────────────────────
#  Obtén los nombres exactos con:  hyprctl devices | grep -A2 "Keyboard"
#  Suelen verse como: "at-translated-set-2-keyboard" o "logitech-usb-keyboard"

LAPTOP_KB="at-translated-set-2-keyboard"          # teclado interno (us)
EXTERNAL_KB=""                                     # deja vacío si aún no lo sabes

LAYOUTS="us,es"          # layouts disponibles (orden del ciclo)
LAYOUT_ICONS=("" "")   # iconos Nerd Font para us y es
LAYOUT_LABELS=("US" "ES")
# ─────────────────────────────────────────────────────────────────────────────

ACTION="${1:-status}"

# Obtiene layout activo de un dispositivo dado su nombre
get_layout() {
    local device="$1"
    hyprctl devices -j 2>/dev/null \
      | jq -r --arg dev "$device" \
        '.keyboards[] | select(.name == $dev) | .active_keymap' 2>/dev/null \
      | head -1
}

# Obtiene el primer layout activo disponible (fallback)
get_any_layout() {
    hyprctl devices -j 2>/dev/null \
      | jq -r '.keyboards[0].active_keymap' 2>/dev/null \
      | head -1
}

# Detecta índice del icono según el keymap reportado por Hyprland
layout_icon() {
    local map="$1"
    case "${map,,}" in
        *spanish*|*español*|*es*)  echo "${LAYOUT_ICONS[1]} ${LAYOUT_LABELS[1]}" ;;
        *)                          echo "${LAYOUT_ICONS[0]} ${LAYOUT_LABELS[0]}" ;;
    esac
}

switch_device() {
    local device="$1"
    [ -z "$device" ] && return
    hyprctl switchxkblayout "$device" next 2>/dev/null
}

case "$ACTION" in
    switch)
        switch_device "$LAPTOP_KB"
        [ -n "$EXTERNAL_KB" ] && switch_device "$EXTERNAL_KB"
        ;;
    switch-laptop)
        switch_device "$LAPTOP_KB"
        ;;
    switch-external)
        [ -n "$EXTERNAL_KB" ] && switch_device "$EXTERNAL_KB" \
          || notify-send -u low "Waybar:" " External Keyboard not set.\nPlease check your settings."
        ;;
    status|*)
        # Obtiene layouts actuales
        LAPTOP_MAP=$(get_layout "$LAPTOP_KB")
        [ -z "$LAPTOP_MAP" ] && LAPTOP_MAP=$(get_any_layout)

        LAPTOP_DISPLAY=$(layout_icon "${LAPTOP_MAP:-us}")

        if [ -n "$EXTERNAL_KB" ]; then
            EXT_MAP=$(get_layout "$EXTERNAL_KB")
            EXT_DISPLAY=$(layout_icon "${EXT_MAP:-es}")
            TEXT="$LAPTOP_DISPLAY  $EXT_DISPLAY"
            TOOLTIP="Laptop: ${LAPTOP_MAP:-US}\\nExternal: ${EXT_MAP:-ES}\\nClic → change for Laptop Layout Keyboard\\nClic → change for External Layout Keyboard"
        else
            TEXT="$LAPTOP_DISPLAY"
            TOOLTIP=" Layout active: ${LAPTOP_MAP:-US}\\nClic for change layout"
        fi

        echo "{\"text\":\"$TEXT\",\"tooltip\":\"$TOOLTIP\",\"class\":\"keyboard\"}"
        ;;
esac