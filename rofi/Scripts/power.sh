#!/usr/bin/env bash
# ~/.config/rofi/Scripts/power.sh
# ─────────────────────────────────────────────────────────────
# Rofi script-mode power menu
# Adjust lock command to match your locker (hyprlock / swaylock)
# ─────────────────────────────────────────────────────────────

declare -A CMD=(
    [" Shutdown"]="systemctl poweroff"
    ["󰜉 Reboot"]="systemctl reboot"
    ["󰤄 Suspend"]="systemctl suspend && hyprlock"
    ["󰍂 Lock"]="hyprlock"
    ["󰍃 Log Out"]="hyprctl dispatch exit"
)

# Ordered list for display
ORDER=(
    " Shutdown"
    "󰜉 Reboot"
    "󰤄 Suspend"
    "󰍂 Lock"
    "󰍃 Log Out"
)

# ── Initial call: print options ───────────────────────────
if [[ -z "$ROFI_RETV" || "$ROFI_RETV" -eq 0 ]]; then
    printf '%s\n' "${ORDER[@]}"
    exit 0
fi

# ── Item selected: execute command ───────────────────────
selected="$1"
if [[ -n "${CMD[$selected]}" ]]; then
    eval "${CMD[$selected]}"
fi
