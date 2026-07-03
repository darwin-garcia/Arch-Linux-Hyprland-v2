#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  profiles.sh — menú de perfiles de energía para Rofi
#  Requiere: power-profiles-daemon (powerprofilesctl), upower
#
#  Ubicación: ~/.config/rofi/scripts/profiles.sh
#  Permisos:  chmod +x ~/.config/rofi/scripts/profiles.sh
#
#  Flujo (rofi-script(5)):
#    ROFI_RETV=0  → llamada inicial: imprime opciones y directivas \0
#    ROFI_RETV=1  → entrada seleccionada: $1 contiene el texto elegido
# ─────────────────────────────────────────────────────────────────────────────

# ── Colores Pango (Tokyo Night) ──────────────────────────────────────────────
C_GREEN="#9ece6a"
C_BLUE="#7aa2f7"
C_CYAN="#2ac3de"
C_ORANGE="#ff9e64"
C_YELLOW="#e0af68"
C_FG="#a9b1d6"
C_MUTED="#565f89"
C_RED="#f7768e"

# ── Batería — obtener información vía upower ─────────────────────────────────
# ── Batería — obtener información vía upower ─────────────────────────────────
_bat_info() {
    # Detecta la primera batería disponible (BAT0, BAT1, etc.)
    local bat_path
    bat_path=$(upower -e 2>/dev/null | grep -E "battery_BAT|battery_macsmc" | head -1)

    if [[ -z "$bat_path" ]]; then
        # Fallback: leer directamente de sysfs
        local sysfs_bat
        sysfs_bat=$(ls /sys/class/power_supply/ 2>/dev/null | grep -iE "^BAT" | head -1)
        if [[ -n "$sysfs_bat" ]]; then
            BAT_PCT=$(cat "/sys/class/power_supply/${sysfs_bat}/capacity" 2>/dev/null || echo "?")
            BAT_STATE=$(cat "/sys/class/power_supply/${sysfs_bat}/status" 2>/dev/null | tr '[:upper:]' '[:lower:]')
            BAT_TIME=""
        else
            BAT_PCT="?"
            BAT_STATE="unknown"
            BAT_TIME=""
        fi
        return
    fi

    # Usamos LC_ALL=C para garantizar que el separador decimal de upower sea un punto (.)
    local info
    info=$(LC_ALL=C upower -i "$bat_path" 2>/dev/null)

    # Porcentaje — elimina el símbolo %
    BAT_PCT=$(awk '/percentage/{gsub(/%/,"",$2); printf "%d", $2}' <<< "$info")
    [[ -z "$BAT_PCT" ]] && BAT_PCT="?"

    # Estado: charging / discharging / fully-charged / pending-charge
    BAT_STATE=$(awk '/state/{print $2}' <<< "$info")

    # Extraer y convertir el tiempo decimal a formato Hh Mm usando awk
    local awk_time_script='
    function format_time(v, u) {
        if (u ~ /^hour/) {
            h = int(v);                     # Extrae la parte entera (horas)
            m = int((v - h) * 60 + 0.5);    # Convierte el decimal restante a minutos
            return (h > 0) ? sprintf("%dh %02dm", h, m) : sprintf("%dm", m);
        }
        if (u ~ /^minute/) {
            return sprintf("%dm", int(v + 0.5)); # Redondea los minutos
        }
        return v " " u;
    }
    /time to empty/ { te = format_time($4, $5) }
    /time to full/  { tf = format_time($4, $5) }
    END { print te "|" tf }'

    local times
    times=$(awk "$awk_time_script" <<< "$info")
    
    # Separar los resultados usando bash string manipulation
    local t_empty="${times%|*}"
    local t_full="${times#*|}"

    case "$BAT_STATE" in
        charging)       BAT_TIME="${t_full}" ;;
        fully-charged)  BAT_TIME="" ;;
        *)              BAT_TIME="${t_empty}" ;;
    esac
}

# ── Icono de batería según porcentaje y estado ───────────────────────────────
_bat_icon() {
    local pct="$1" state="$2"
    case "$state" in
        charging)      echo "󰂄" ; return ;;
        fully-charged) echo "󰁹" ; return ;;
    esac
    local p=${pct//[^0-9]/}
    if   (( p >= 90 )); then echo "󰁹"
    elif (( p >= 80 )); then echo "󰂂"
    elif (( p >= 70 )); then echo "󰂀"
    elif (( p >= 60 )); then echo "󰁿"
    elif (( p >= 50 )); then echo "󰁾"
    elif (( p >= 40 )); then echo "󰁽"
    elif (( p >= 30 )); then echo "󰁼"
    elif (( p >= 20 )); then echo "󰁻"
    elif (( p >= 10 )); then echo "󰁺"
    else                    echo "󰂎"
    fi
}

# ── Color del porcentaje según nivel ─────────────────────────────────────────
_bat_color() {
    local p=${1//[^0-9]/}
    if   (( p >= 50 )); then echo "$C_GREEN"
    elif (( p >= 25 )); then echo "$C_YELLOW"
    elif (( p >= 10 )); then echo "$C_ORANGE"
    else                     echo "$C_RED"
    fi
}

# ── Perfil actual ────────────────────────────────────────────────────────────
_current_profile() {
    powerprofilesctl get 2>/dev/null || echo "unknown"
}

# ── Índice del perfil actual (para \0active) ─────────────────────────────────
#   0 → performance  |  1 → balanced  |  2 → power-saver
_active_index() {
    case "$1" in
        performance)  echo "0" ;;
        balanced)     echo "1" ;;
        power-saver)  echo "2" ;;
        *)            echo "1" ;;   # fallback a balanced
    esac
}

# ── Icono del perfil ─────────────────────────────────────────────────────────
_profile_icon() {
    case "$1" in
        performance)  echo "󱐋" ;;
        balanced)     echo "⚖" ;;
        power-saver)  echo "󰌪" ;;
        *)            echo "?" ;;
    esac
}

# ── Color del perfil para el message bar ─────────────────────────────────────
_profile_color() {
    case "$1" in
        performance)  echo "$C_ORANGE" ;;
        balanced)     echo "$C_BLUE"   ;;
        power-saver)  echo "$C_GREEN"  ;;
        *)            echo "$C_FG"     ;;
    esac
}

# ═════════════════════════════════════════════════════════════════════════════
#  ROFI_RETV=1  — el usuario seleccionó una entrada
# ═════════════════════════════════════════════════════════════════════════════
if [[ "${ROFI_RETV}" == "1" ]]; then
    case "$1" in
        *"Performance"*)
            # coproc: lanza en background para no bloquear Rofi (ver rofi-script(5))
            coproc ( powerprofilesctl set performance > /dev/null 2>&1 )
            ;;
        *"Balanced"*)
            coproc ( powerprofilesctl set balanced > /dev/null 2>&1 )
            ;;
        *"Power Saver"*)
            coproc ( powerprofilesctl set power-saver > /dev/null 2>&1 )
            ;;
    esac
    # Sin salida → Rofi cierra
    exit 0
fi

# ═════════════════════════════════════════════════════════════════════════════
#  ROFI_RETV=0  — llamada inicial: construir el menú
# ═════════════════════════════════════════════════════════════════════════════

_bat_info
CURRENT=$(_current_profile)
BAT_ICON=$(_bat_icon   "$BAT_PCT" "$BAT_STATE")
BAT_COL=$(_bat_color   "$BAT_PCT")
PROF_ICON=$(_profile_icon  "$CURRENT")
PROF_COL=$(_profile_color  "$CURRENT")
ACTIVE=$(_active_index "$CURRENT")

# ── Construir cadena de tiempo restante ─────────────────────────────────────
if [[ "$BAT_STATE" == "fully-charged" ]]; then
    TIME_SPAN="<span foreground='${C_GREEN}'>󰂄 Cargado</span>"
elif [[ "$BAT_STATE" == "charging" && -n "$BAT_TIME" ]]; then
    TIME_SPAN="<span foreground='${C_CYAN}'>󰂄 ${BAT_TIME}</span>"
elif [[ -n "$BAT_TIME" ]]; then
    TIME_SPAN="<span foreground='${C_MUTED}'>󰥔 ${BAT_TIME}</span>"
else
    TIME_SPAN="<span foreground='${C_MUTED}'>󰥔 —</span>"
fi

# ── Message bar — Pango markup ───────────────────────────────────────────────
#   <bat_icon> <pct>%   <prof_icon> <profile>   <time>
MESSAGE=$(printf \
    '<span foreground="%s">%s</span>  <span foreground="%s"><b>%s%%</b></span>     <span foreground="%s">%s</span>  <span foreground="%s">%s</span>     %s' \
    "$BAT_COL"  "$BAT_ICON" \
    "$BAT_COL"  "$BAT_PCT" \
    "$PROF_COL" "$PROF_ICON" \
    "$PROF_COL" "$CURRENT" \
    "$TIME_SPAN"
)

# ── Directivas globales (deben ir antes de las entradas) ─────────────────────
printf '\0markup-rows\x1ftrue\n'        # habilita Pango en las filas
printf '\0no-custom\x1ftrue\n'          # solo acepta entradas listadas
printf '\0message\x1f%s\n' "$MESSAGE"  # status bar de batería
printf '\0active\x1f%s\n'  "$ACTIVE"   # marca el perfil activo

# ── Entradas del menú (Pango markup habilitado) ──────────────────────────────
#   Formato: icono  Nombre      descripción (muted)
printf '<span foreground="%s" size="large">󱐋</span>  <b>Performance</b>  <span foreground="%s" size="small">CPU sin límite</span>\n' \
    "$C_ORANGE" "$C_MUTED"

printf '<span foreground="%s" size="large">⚖</span>  <b>Balanced</b>  <span foreground="%s" size="small">Balance energía/rendimiento</span>\n' \
    "$C_BLUE" "$C_MUTED"

printf '<span foreground="%s" size="large">󰌪</span>  <b>Power Saver</b>  <span foreground="%s" size="small">Máxima autonomía</span>\n' \
    "$C_GREEN" "$C_MUTED"
