#!/bin/bash
# network.sh — Muestra estado de red para hyprlock (Optimizado)
# Requiere: nmcli (NetworkManager)

# ── Verificar que nmcli esté disponible ───────────────────────────────────────
if ! command -v nmcli &>/dev/null; then
    echo -e "󰤮\tSin nmcli"
    exit 1
fi

# ── Modo avión ────────────────────────────────────────────────────────────────
networking=$(nmcli -t -f NETWORKING g 2>/dev/null)
if [[ "$networking" == "disabled" ]]; then
    echo -e "󰀝\tModo avión"
    exit 0
fi

# ── Ethernet ──────────────────────────────────────────────────────────────────
# Forma rápida de ver si hay una conexión ethernet activa
eth_status=$(nmcli -t -f TYPE,STATE dev 2>/dev/null | grep -E '^(802-3-ethernet|ethernet):connected')
if [[ -n "$eth_status" ]]; then
    echo -e "󰈁\tEthernet"
    exit 0
fi

# ── WiFi deshabilitado (sin modo avión) ───────────────────────────────────────
wifi_status=$(nmcli -t -f WIFI g 2>/dev/null)
if [[ "$wifi_status" != "enabled" ]]; then
    echo -e "󰤮\tWiFi apagado"
    exit 0
fi

# ── WiFi: buscar conexión activa de forma RÁPIDA ──────────────────────────────
# 'nmcli dev wifi' causa lag porque escanea redes. Leer la conexión actual es instantáneo.
ssid=$(nmcli -t -f TYPE,CONNECTION dev 2>/dev/null | awk -F':' '$1 ~ /802-11-wireless|wifi/ {print $2}' | head -n 1)

if [[ -z "$ssid" || "$ssid" == "disconnected" ]]; then
    echo -e "󰤮\tDesconectado"
    exit 0
fi

# ── Obtener intensidad de señal sin causar lag ────────────────────────────────
# 1. Obtenemos el nombre de la interfaz (ej. wlan0)
interface=$(nmcli -t -f TYPE,DEVICE dev 2>/dev/null | awk -F':' '$1 ~ /802-11-wireless|wifi/ {print $2}' | head -n 1)

signal=100
if [[ -n "$interface" ]] && [[ -f /proc/net/wireless ]]; then
    # 2. Extraemos la calidad de la señal directamente del archivo del kernel
    link_quality=$(awk "/$interface:/ {print \$3}" /proc/net/wireless | tr -d '.')
    if [[ -n "$link_quality" ]]; then
        # La calidad máxima en el kernel de Linux suele ser 70
        signal=$(( link_quality * 100 / 70 ))
        signal=$(( signal < 0 ? 0 : (signal > 100 ? 100 : signal) ))
    fi
fi

# ── Icono según intensidad de señal ───────────────────────────────────────────
wifi_icons=("󰤯" "󰤟" "󰤢" "󰤥" "󰤨")
icon_index=$(( signal / 25 ))
(( icon_index > 4 )) && icon_index=4
wifi_icon="${wifi_icons[$icon_index]}"

# ── Salida Final ──────────────────────────────────────────────────────────────
# 'echo -e' traduce '\t' en un espacio de tabulación real y forzamos a mostrar el SSID
echo -e "$wifi_icon\t$ssid"