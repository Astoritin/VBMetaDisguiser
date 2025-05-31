#!/system/bin/sh
SKIPUNZIP=1

CONFIG_DIR=/data/adb/vbmetadisguiser
LOG_DIR="$CONFIG_DIR/logs"
CONFIG_FILE="$CONFIG_DIR/vbmeta.conf"

VERIFY_DIR="$TMPDIR/.aa_verify"

MOD_NAME="$(grep_prop name "${TMPDIR}/module.prop")"
MOD_VER="$(grep_prop version "${TMPDIR}/module.prop") ($(grep_prop versionCode "${TMPDIR}/module.prop"))"
MOD_INTRO="A Magisk module to disguise the props of vbmeta, security patch date and encryption status."

[ ! -d "$VERIFY_DIR" ] && mkdir -p "$VERIFY_DIR"

echo "- Extract aa-util.sh"
unzip -o "$ZIPFILE" 'aa-util.sh' -d "$TMPDIR" >&2
if [ ! -f "$TMPDIR/aa-util.sh" ]; then
  echo "! Failed to extract aa-util.sh!"
  abort "! This zip may be corrupted!"
fi

. "$TMPDIR/aa-util.sh"

logowl "Setting up $MOD_NAME"
logowl "Version: $MOD_VER"
logowl_init "$LOG_DIR"
install_env_check
show_system_info
logowl "Install from $ROOT_SOL app"
logowl "Essential checks"
extract "$ZIPFILE" 'aa-util.sh' "$VERIFY_DIR"
extract "$ZIPFILE" 'customize.sh' "$VERIFY_DIR"
logowl_clean "$LOG_DIR" 20
logowl "Extract module files"
extract "$ZIPFILE" 'aa-util.sh' "$MODPATH"
extract "$ZIPFILE" 'module.prop' "$MODPATH"
extract "$ZIPFILE" 'action.sh' "$MODPATH"
extract "$ZIPFILE" 'post-fs-data.sh' "$MODPATH"
extract "$ZIPFILE" 'service.sh' "$MODPATH"
extract "$ZIPFILE" 'uninstall.sh' "$MODPATH"
if [ ! -f "$CONFIG_DIR/vbmeta.conf" ]; then
    logowl "vbmeta.conf does NOT exist"
    extract "$ZIPFILE" 'vbmeta.conf' "$CONFIG_DIR"    
else
    logowl "vbmeta.conf already exists"
    logowl "vbmeta.conf will NOT be overwritten"
fi
rm -rf "$VERIFY_DIR"
logowl "Set permission"
set_permission_recursive "$MODPATH" 0 0 0755 0644
logowl "Welcome to use $MOD_NAME!"
DESCRIPTION="[✨Reboot to take effect.] $MOD_INTRO"
update_config_var "description" "$DESCRIPTION" "$MODPATH/module.prop"
