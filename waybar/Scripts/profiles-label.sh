#!/usr/bin/env bash
case "$(powerprofilesctl get 2>/dev/null)" in
    performance)  echo "󱐋" ;;
    balanced)     echo "⚖" ;;
    power-saver)  echo "󰌪" ;;
    *)            echo "?" ;;
esac