#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
#  Descarta todas las notificaciones y resetea contador
# ─────────────────────────────────────────────────────────────────────────────
makoctl dismiss -a 2>/dev/null
echo 0 > /tmp/mako_notif_count