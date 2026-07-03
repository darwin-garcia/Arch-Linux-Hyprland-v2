#!/bin/bash
# power_action.sh — Ejecuta reboot/poweroff previa autenticación PAM
# Uso: power_action.sh reboot | poweroff
#
# Requiere: pkexec (polkit) — presente por defecto en Arch/Fedora/Ubuntu
# El diálogo de contraseña lo gestiona el agente polkit activo
# (hyprpolkitagent, polkit-gnome-authentication-agent, etc.)

ACTION="${1:-}"

case "$ACTION" in
    reboot|poweroff) ;;
    *)
        echo "Uso: $0 reboot | poweroff" >&2
        exit 1
        ;;
esac

# pkexec autentica al usuario con PAM antes de ejecutar el comando.
# systemctl reboot/poweroff requiere privilegios de root → polkit pide contraseña.
pkexec systemctl "$ACTION"