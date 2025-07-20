#!/system/bin/sh
SKIPUNZIP=1

CONFIG_DIR=/data/adb/vbmetadisguiser

CONFIG_FILE="$CONFIG_DIR/vbmeta.conf"
LOG_DIR="$CONFIG_DIR/logs"

MOD_NAME="$(grep_prop name "${TMPDIR}/module.prop")"
MOD_VER="$(grep_prop version "${TMPDIR}/module.prop") ($(grep_prop versionCode "${TMPDIR}/module.prop"))"
MOD_INTRO="Disguise VBMeta properties."

unzip -o "$ZIPFILE" "aa-util.sh" -d "$TMPDIR" >&2
if [ ! -f "$TMPDIR/aa-util.sh" ]; then
    ui_print "! Failed to extract aa-util.sh!"
    abort "! This zip may be corrupted!"
fi

. "$TMPDIR/aa-util.sh"

logowl "Setting up $MOD_NAME"
logowl "Version: $MOD_VER"
logowl_init "$LOG_DIR"
show_system_info
install_env_check
logowl "Install from $ROOT_SOL app"
logowl "Root: $ROOT_SOL_DETAIL"
extract "customize.sh" "$TMPDIR"
extract "aa-util.sh"
extract "module.prop"
extract "action.sh"
extract "post-fs-data.sh"
extract "service.sh"
extract "uninstall.sh"
[ ! -f "$CONFIG_FILE" ] && extract "vbmeta.conf" "$CONFIG_DIR"
remove_config_var "update_realtime" "$CONFIG_FILE"
remove_config_var "update_period" "$CONFIG_FILE"
remove_config_var "addon_d_slay" "$CONFIG_FILE"
if ! get_config_var "security_patch_disguise" "$CONFIG_FILE"; then
    update_config_var "security_patch_disguise" "false" "$CONFIG_FILE"
fi
logowl "Set permission"
set_permission_recursive "$MODPATH" 0 0 0755 0644
logowl "Welcome to use $MOD_NAME!"
DESCRIPTION="[🙂Reboot to take effect.] $MOD_INTRO"
update_config_var "description" "$DESCRIPTION" "$MODPATH/module.prop"