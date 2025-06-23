CONFIG_DIR="/data/adb/vbmetadisguiser"
SLAIN_PROPS="$CONFIG_DIR/slain_props.prop"

[ -f "$SLAIN_PROPS" ] && resetprop -p -f "$SLAIN_PROPS"
rm -rf "$CONFIG_DIR"