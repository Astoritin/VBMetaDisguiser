#!/system/bin/sh
SKIPUNZIP=1

CONFIG_DIR_OLD="/data/adb/vbmetadisguiser"
CONFIG_DIR="/data/adb/vbmeta_disguiser"

CONFIG_FILE="$CONFIG_DIR/vbmeta.conf"

MOD_UPDATE_PATH="$(dirname "$MODPATH")"
MOD_PATH="${MOD_UPDATE_PATH%_update}"
MOD_PATH_OLD="$MOD_PATH/vbmetadisguiser"

POST_D="/data/adb/post-fs-data.d/"
SERV_D="/data/adb/service.d/"
CLEANUP_SH="vbmeta_disguiser_cleanup.sh"
BLSPOOF_SH="vbmeta_disguiser_blspoof.sh"
CLEANUP_PATH="${POST_D}${CLEANUP_SH}"
BLSPOOF_PATH="${SERV_D}${BLSPOOF_SH}"

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

[ -d "$CONFIG_DIR_OLD" ] && mv "$CONFIG_DIR_OLD" "$CONFIG_DIR"

ui_print "- Setting up $MOD_NAME"
ui_print "- Version: $MOD_VER"
show_system_info
install_env_check
ui_print "- Installing from $ROOT_SOL app"
ui_print "- Root: $ROOT_SOL_DETAIL"
[ -d "$MOD_PATH_OLD" ] && rm -f "$MOD_PATH_OLD/update"
[ -d "$MOD_PATH_OLD" ] && touch "$MOD_PATH_OLD/remove"
extract "customize.sh" "$TMPDIR"
extract "wanderer.sh"
extract "action.sh"
extract "module.prop"
extract "post-fs-data.sh"
rm -f "/data/adb/service.d/vd_bl_props_reset.sh"
extract "$CLEANUP_SH"
extract "$BLSPOOF_SH"
cat "$MODPATH/${CLEANUP_SH}" > "$CLEANUP_PATH"
cat "$MODPATH/${BLSPOOF_SH}" > "$BLSPOOF_PATH"
chmod +x "$CLEANUP_PATH"
chmod +x "$BLSPOOF_PATH"
extract "service.sh"
extract "uninstall.sh"
[ ! -f "$CONFIG_FILE" ] && extract "vbmeta.conf" "$CONFIG_DIR"
DESCRIPTION="[⏳Reboot to take effect] $MOD_INTRO"
remove_config_var "update_realtime" "$CONFIG_FILE"
remove_config_var "update_period" "$CONFIG_FILE"
remove_config_var "addon_d_slay" "$CONFIG_FILE"
remove_config_var "build_type_spoof_in_post_fs_data" "$CONFIG_FILE"
update_config_var "description" "$MODPATH/module.prop" "$DESCRIPTION"
update_config_var "security_patch_disguise" "$CONFIG_FILE" "false" "true"
update_config_var "bootloader_props_spoof" "$CONFIG_FILE" "false" "true"
update_config_var "build_type_spoof" "$CONFIG_FILE" "false" "true"
update_config_var "restore_after_disable" "$CONFIG_FILE" "true" "true"
update_config_var "custom_build_fingerprint" "$CONFIG_FILE" "" "true"
update_config_var "outdated_pi_props_slay" "$CONFIG_FILE" "false" "true"
ui_print "- Setting permission"
set_perm_recursive "$MODPATH" 0 0 0755 0644
ui_print "- Welcome to use $MOD_NAME!"