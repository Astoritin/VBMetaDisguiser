#!/system/bin/sh
SKIPUNZIP=1

CONFIG_DIR=/data/adb/vbmetadisguiser

CONFIG_FILE="$CONFIG_DIR/vbmeta.conf"
LOG_DIR="$CONFIG_DIR/logs"

MOD_PROP="${TMPDIR}/module.prop"
MOD_NAME="$(grep_prop name "$MOD_PROP")"
MOD_VER="$(grep_prop version "$MOD_PROP") ($(grep_prop versionCode "$MOD_PROP"))"
MOD_INTRO="Disguise VBMeta properties."

unzip -o "$ZIPFILE" "wanderer.sh" -d "$TMPDIR" >&2
if [ ! -f "$TMPDIR/wanderer.sh" ]; then
    ui_print "! Failed to extract wanderer.sh!"
    abort "! This zip may be corrupted!"
fi

. "$TMPDIR/wanderer.sh"

logowl "Setting up $MOD_NAME"
logowl "Version: $MOD_VER"
logowl_init "$LOG_DIR"
show_system_info
install_env_check
logowl "Install from $ROOT_SOL app"
logowl "Root: $ROOT_SOL_DETAIL"
extract "customize.sh" "$TMPDIR"
extract "action.sh"
extract "module.prop"
extract "post-fs-data.sh"
extract "service.sh"
extract "uninstall.sh"
[ ! -f "$CONFIG_FILE" ] && extract "vbmeta.conf" "$CONFIG_DIR"
extract "wanderer.sh"
DESCRIPTION="[🙂Reboot to take effect.] $MOD_INTRO"
remove_config_var "update_realtime" "$CONFIG_FILE"
remove_config_var "update_period" "$CONFIG_FILE"
remove_config_var "addon_d_slay" "$CONFIG_FILE"
update_config_var "description" "$DESCRIPTION" "$MODPATH/module.prop"
append_config_var "security_patch_disguise" "$CONFIG_FILE" "false"
append_config_var "bootloader_props_spoof" "$CONFIG_FILE" "false"
logowl "Set permission"
set_permission_recursive "$MODPATH" 0 0 0755 0644
logowl "Welcome to use $MOD_NAME!"