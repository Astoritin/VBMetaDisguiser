#!/system/bin/sh
MODDIR=${0%/*}

CONFIG_DIR="/data/adb/bloatwareslayer"

if [ -n "$CONFIG_DIR" ]; then
    rm -rf "$CONFIG_DIR"
fi
