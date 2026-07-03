#!/bin/bash

BAT=$(ls /sys/class/power_supply/ | grep '^BAT' | head -n1)
BATPATH="/sys/class/power_supply/$BAT"

manufacturer=$(cat "$BATPATH/manufacturer" 2>/dev/null || echo "N/D")
model=$(cat "$BATPATH/model_name" 2>/dev/null || echo "N/D")
serial=$(cat "$BATPATH/serial_number" 2>/dev/null || echo "N/D")

cycles=$(cat "$BATPATH/cycle_count" 2>/dev/null || echo "N/D")

full=$(cat "$BATPATH/energy_full" 2>/dev/null)
design=$(cat "$BATPATH/energy_full_design" 2>/dev/null)

if [[ -n "$full" && -n "$design" && "$design" -gt 0 ]]; then
    health=$(( full * 100 / design ))
else
    health="N/D"
fi

tooltip=" Current Cycles: $cycles • 󱈏 Health: ${health}% • 󰕮 $manufacturer •  $model • # $serial"

echo "{\"text\":\"\",\"tooltip\":\"$tooltip\"}"