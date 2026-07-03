#!/bin/bash
# infonlock.sh — Indicador de batería para hyprlock
# - Sin batería (Desktop): no muestra nada
# - Descargando: icono por nivel cada 10%
# - Cargando:    icono de carga progresiva por nivel
# - Full:        icono de batería llena con enchufe

# ── Detectar batería ──────────────────────────────────────────────────────────
bat_path=""
for bat in /sys/class/power_supply/BAT{0,1,2} /sys/class/power_supply/BATT; do
    if [[ -f "$bat/capacity" && -f "$bat/status" ]]; then
        bat_path="$bat"
        break
    fi
done

# Sin batería → equipo de escritorio, no mostrar nada
[[ -z "$bat_path" ]] && exit 0

# ── Leer valores ──────────────────────────────────────────────────────────────
battery_percentage=$(< "$bat_path/capacity")
battery_status=$(< "$bat_path/status")

# Validar que el porcentaje sea numérico
if ! [[ "$battery_percentage" =~ ^[0-9]+$ ]]; then
    echo "󰂑\t?%"
    exit 0
fi

# Clamp 0–100
(( battery_percentage < 0  )) && battery_percentage=0
(( battery_percentage > 100 )) && battery_percentage=100

# ── Iconos ────────────────────────────────────────────────────────────────────
# Descargando: un icono cada 10% (índices 0–9, el 100% usa el índice 9)
battery_icons=(
    "󰂃"   # 0–9%   crítico
    "󰁺"   # 10–19%
    "󰁻"   # 20–29%
    "󰁼"   # 30–39%
    "󰁽"   # 40–49%
    "󰁾"   # 50–59%
    "󰁿"   # 60–69%
    "󰂀"   # 70–79%
    "󰂁"   # 80–89%
    "󰁹"   # 90–100%
)

# Cargando: icono de carga progresiva por nivel
charging_icons=(
    "󰢟"   # 0–9%   cargando crítico
    "󰢜"   # 10–19% cargando
    "󰂆"   # 20–29% cargando
    "󰂇"   # 30–39% cargando
    "󰂈"   # 40–49% cargando
    "󰢝"   # 50–59% cargando
    "󰂉"   # 60–69% cargando
    "󰢞"   # 70–79% cargando
    "󰂊"   # 80–89% cargando
    "󰂋"   # 90–99% cargando
)

# ── Calcular índice (0–9, sin desborde) ───────────────────────────────────────
if (( battery_percentage >= 100 )); then
    icon_index=9
else
    icon_index=$(( battery_percentage / 10 ))
fi

# ── Seleccionar icono según estado ────────────────────────────────────────────
case "$battery_status" in
    Charging)
        battery_icon="${charging_icons[$icon_index]}"
        ;;
    Full)
        battery_icon="󰁹"   # llena con enchufe
        ;;
    *)  # Discharging, Unknown, Not charging
        battery_icon="${battery_icons[$icon_index]}"
        ;;
esac

# ── Salida ────────────────────────────────────────────────────────────────────
echo "$battery_icon $battery_percentage%"