#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
#  updates_status.sh  –  Waybar exec: emite JSON con conteo y lista de paquetes
#  Ruta: ~/.config/waybar/scripts/updates_status.sh
# ─────────────────────────────────────────────────────────────────────────────

CHECKER="$HOME/.config/hypr/Scripts/check-updates.sh"

# Ejecuta el checker; si no existe o falla, asume 0 actualizaciones
if [ -x "$CHECKER" ]; then
    PKGLIST=$("$CHECKER" 2>/dev/null)
else
    PKGLIST=""
fi

COUNT=$(echo "$PKGLIST" | grep -c '[^[:space:]]')   # líneas no vacías

if [ "$COUNT" -gt 0 ]; then
    # Construye el tooltip: primeras 20 líneas + aviso si hay más
    PREVIEW=$(echo "$PKGLIST" | head -20 | awk '{print $1 "  " $2 " → " $4}')
    if [ "$COUNT" -gt 20 ]; then
        PREVIEW="$PREVIEW\n… y $((COUNT - 20)) más"
    fi
    # Escapa las comillas para JSON
    TOOLTIP=$(printf '%s' "$PREVIEW" | sed 's/\\/\\\\/g; s/"/\\"/g')

    echo "{\"text\":\" $COUNT\",\"tooltip\":\" $COUNT Updates Aviable\\n──────────────────────\\n$TOOLTIP\",\"class\":\"has-updates\"}"
else
    echo "{\"text\":\" \",\"tooltip\":\"Your system was updated. ✓\",\"class\":\"up-to-date\"}"
fi