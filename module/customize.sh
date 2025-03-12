#!/system/bin/sh
SKIPUNZIP=1

CONFIG_DIR=/data/adb/vbmetadisguiser
CONFIG_FILE="$CONFIG_DIR/vbmeta.conf"
LOG_DIR="$CONFIG_DIR/logs"
VERIFY_DIR="$TMPDIR/.aa_vd_verify"
MOD_NAME="$(grep_prop name "${TMPDIR}/module.prop")"
MOD_VER="$(grep_prop version "${TMPDIR}/module.prop") ($(grep_prop versionCode "${TMPDIR}/module.prop"))"

echo "- Extract aautilities.sh"
unzip -o "$ZIPFILE" 'aautilities.sh' -d "$TMPDIR" >&2
if [ ! -f "$TMPDIR/aautilities.sh" ]; then
  echo "! Failed to extract aautilities.sh!"
  abort "! This zip may be corrupted!"
fi

. "$TMPDIR/aautilities.sh"

install_env_check
init_logowl "$LOG_DIR"
logowl "Setting up $MOD_NAME"
logowl "Version: $MOD_VER"
show_system_info
clean_old_logs "$LOG_DIR" 20

if [ "$API" -lt 27 ]; then
    logowl "Detect Android version is lower than 8 (oreo)!" "ERROR"
    logowl "$MOD_NAME does not support Android 8 and lower"
    about "since VBMeta props does NOT exist in these old Android version!"
fi

logowl "Extract module files"
extract "$ZIPFILE" 'aautilities.sh' "$VERIFY_DIR"
extract "$ZIPFILE" 'customize.sh' "$VERIFY_DIR"
extract "$ZIPFILE" 'aautilities.sh' "$MODPATH"
extract "$ZIPFILE" 'module.prop' "$MODPATH"
extract "$ZIPFILE" 'service.sh' "$MODPATH"
extract "$ZIPFILE" 'uninstall.sh' "$MODPATH"

if [ ! -f "$CONFIG_DIR/vbmeta.conf" ]; then
    logowl "vbmeta.conf does not exist" "TIPS"
    extract "$ZIPFILE" 'vbmeta.conf' "$TMPDIR"
    mv "$TMPDIR/vbmeta.conf" "$CONFIG_DIR/vbmeta.conf" || abort "! Failed to create vbmeta.conf!"
else
    logowl "Detect vbmeta.conf already existed"
    logowl "Skip overwriting vbmeta.conf"
fi

set_module_files_perm
logowl "Welcome to use ${MOD_NAME}!"
