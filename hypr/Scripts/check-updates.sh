#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
#  checkupdates.sh  –  Lista paquetes con actualización disponible
#  Ruta: ~/.config/hypr/Scripts/checkupdates.sh
#
#  Salida: una línea por paquete (para que  wc -l  cuente correctamente)
#  Requiere: pacman-contrib  (para el comando checkupdates)
#            Opcional: yay o paru para paquetes AUR
#
#  Instalación de dependencia:
#    sudo pacman -S pacman-contrib
# ─────────────────────────────────────────────────────────────────────────────

# ── Detecta helper AUR disponible ──────────────────────────────────────────
AUR_HELPER=""
for helper in paru yay; do
    command -v "$helper" &>/dev/null && AUR_HELPER="$helper" && break
done

# ── Actualizaciones de repositorios oficiales ───────────────────────────────
# checkupdates usa una copia temporal de la base de datos — no requiere sudo
# y no interfiere con el sistema de paquetes.
OFFICIAL=$(checkupdates 2>/dev/null)

# ── Actualizaciones AUR (si hay helper) ────────────────────────────────────
AUR=""
if [ -n "$AUR_HELPER" ]; then
    case "$AUR_HELPER" in
        paru) AUR=$(paru -Qua 2>/dev/null) ;;
        yay)  AUR=$(yay  -Qua 2>/dev/null) ;;
    esac
fi

# ── Combina y emite (una línea por paquete) ─────────────────────────────────
{
    [ -n "$OFFICIAL" ] && echo "$OFFICIAL"
    [ -n "$AUR"      ] && echo "$AUR"
} | grep -v '^[[:space:]]*$'    # filtra líneas vacías para que wc -l sea exacto