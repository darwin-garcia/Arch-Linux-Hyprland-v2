#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
#  Notification Center
# ─────────────────────────────────────────────────────────────────────────────
COUNTER="/tmp/mako_notif_count"
COUNT=$(cat "$COUNTER" 2>/dev/null || echo 0)

if [ "$COUNT" -gt 0 ]; then
    echo "{\"text\":\"󰂚 $COUNT\",\"tooltip\":\"$COUNT Notifications Pending\\nClic → Clear All\\nClic derecho → Restore Last Notification\",\"class\":\"has-notif\"}"
else
    echo "{\"text\":\"󰂜\",\"tooltip\":\"󰂚 Clear. All Done. :-)\",\"class\":\"empty\"}"
fi