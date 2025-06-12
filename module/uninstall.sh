CONFIG_DIR="/data/adb/vbmetadisguiser"
LOG_DIR="$CONFIG_DIR/logs"
SLAIN_PROPS="$LOG_DIR/slain_props.prop"

[ -f "$SLAIN_PROPS" ] && resetprop -p -f "$SLAIN_PROPS"

rm -rf "$CONFIG_DIR"