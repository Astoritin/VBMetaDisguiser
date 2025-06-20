#!/system/bin/sh
SKIPUNZIP=1

CONFIG_DIR=/data/adb/vbmetadisguiser

CONFIG_FILE="$CONFIG_DIR/vbmeta.conf"
LOG_DIR="$CONFIG_DIR/logs"

VERIFY_DIR="$TMPDIR/.aa_verify"

MOD_NAME="$(grep_prop name "${TMPDIR}/module.prop")"
MOD_VER="$(grep_prop version "${TMPDIR}/module.prop") ($(grep_prop versionCode "${TMPDIR}/module.prop"))"
MOD_INTRO="Disguise the properties of vbmeta, security patch date and encryption status."

[ ! -d "$VERIFY_DIR" ] && mkdir -p "$VERIFY_DIR"

unzip -o "$ZIPFILE" 'aa-util.sh' -d "$TMPDIR" >&2
if [ ! -f "$TMPDIR/aa-util.sh" ]; then
    echo "! Failed to extract aa-util.sh!"
    abort "! This zip may be corrupted!"
fi

. "$TMPDIR/aa-util.sh"

logowl "Setting up $MOD_NAME"
logowl "Version: $MOD_VER"
logowl_init "$LOG_DIR"
show_system_info
install_env_check
logowl "Install from $ROOT_SOL app"
extract "$ZIPFILE" 'customize.sh' "$VERIFY_DIR"
extract "$ZIPFILE" 'aa-util.sh' "$MODPATH"
extract "$ZIPFILE" 'module.prop' "$MODPATH"
extract "$ZIPFILE" 'action.sh' "$MODPATH"
extract "$ZIPFILE" 'post-fs-data.sh' "$MODPATH"
extract "$ZIPFILE" 'service.sh' "$MODPATH"
extract "$ZIPFILE" 'uninstall.sh' "$MODPATH"
if [ ! -f "$CONFIG_FILE" ]; then
    extract "$ZIPFILE" 'vbmeta.conf' "$CONFIG_DIR"    
fi
rm -rf "$VERIFY_DIR"
logowl "Set permission"
set_permission_recursive "$MODPATH" 0 0 0755 0644
logowl "Welcome to use $MOD_NAME!"
DESCRIPTION="[✨Reboot to take effect.] $MOD_INTRO"
update_config_var "description" "$DESCRIPTION" "$MODPATH/module.prop"
