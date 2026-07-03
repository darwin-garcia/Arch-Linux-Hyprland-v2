#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
#  Notification Center
# ─────────────────────────────────────────────────────────────────────────────
COUNTER="/tmp/mako_notif_count"

# Inicializa el contador al arrancar
echo 0 > "$COUNTER"

# Escucha TODAS las llamadas Notify que llegan al bus de sesión.
# Cada vez que una app manda una notificación, mako recibe un "Notify".
dbus-monitor --session \
  "type='method_call',interface='org.freedesktop.Notifications',member='Notify'" \
  2>/dev/null \
| grep --line-buffered "member=Notify" \
| while IFS= read -r _; do
    count=$(cat "$COUNTER" 2>/dev/null || echo 0)
    echo $((count + 1)) > "$COUNTER"
  done