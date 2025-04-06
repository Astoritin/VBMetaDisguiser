#!/system/bin/sh
MODDIR=${0%/*}

CONFIG_DIR="/data/adb/vbmetadisguiser"

if [ -n "$CONFIG_DIR" ] && [ -d "$CONFIG_DIR" ] && [ "$CONFIG_DIR" != "/" ]; then
    rm -rf "$CONFIG_DIR"
fi
