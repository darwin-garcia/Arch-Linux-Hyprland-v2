#!/bin/bash

STATE_FILE="/tmp/hypr_lid_state"

case "$1" in
  close)
    # Guardar estado actual de monitores antes de cerrar
    hyprctl monitors -j > "$STATE_FILE"

    # Apagar pantalla del laptop
    hyprctl keyword monitor "eDP-1, disable"

    # Reubicar el ultrawide en 0x0 ya que es el único activo
    hyprctl keyword monitor "DP-4, 1920x1080@60, 0x0, 1"
    ;;
    ;;

  open)
    if [ ! -f "$STATE_FILE" ]; then
      # Sin estado guardado, restaurar con defaults
      hyprctl keyword monitor "eDP-1, preferred, auto, 1.25"
      exit 0
    fi

    # Leer cuántos monitores había activos
    MONITOR_COUNT=$(jq 'length' "$STATE_FILE")

    if [ "$MONITOR_COUNT" -ge 2 ]; then
      # Había segundo monitor: restaurar extendido
      hyprctl keyword monitor "eDP-1, 2560x1440@60, 0x0, 1.33"
      hyprctl keyword monitor "DP-4, 1920x1080@60, 1920x0, 1.25" # <- Ajustar la resolucion del monitor externo
    else
      # Solo había pantalla del laptop
      hyprctl keyword monitor "eDP-1, preferred, auto, 1.25"
    fi

    rm -f "$STATE_FILE"
    ;;
esac