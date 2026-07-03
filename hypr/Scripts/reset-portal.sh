#!/bin/bash
sleep 1
# Matar procesos existentes
killall xdg-desktop-portal-hyprland
killall xdg-desktop-portal-gtk
killall xdg-desktop-portal

# Iniciar el portal de Hyprland y esperar un momento
/usr/lib/xdg-desktop-portal-hyprland &
sleep 2

# Iniciar el portal principal (este llamará al de GTK automáticamente cuando se necesite)
./usr/lib/xdg-desktop-portal &