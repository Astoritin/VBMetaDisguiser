#!/system/bin/sh
SKIPUNZIP=1

CONFIG_DIR=/data/adb/vbmetadisguiser
CONFIG_FILE="$CONFIG_DIR/vbmeta.conf"
LOG_DIR="$CONFIG_DIR/logs"
VERIFY_DIR="$TMPDIR/.aa_verify"
MOD_NAME="$(grep_prop name "${TMPDIR}/module.prop")"
MOD_VER="$(grep_prop version "${TMPDIR}/module.prop") ($(grep_prop versionCode "${TMPDIR}/module.prop"))"

if [ "$API" -lt 27 ]; then
    logowl "Detect Android version is lower than 8 (oreo)!" "ERROR"
    logowl "$MOD_NAME does not support Android 8 and lower"
    about "since VBMeta props does NOT exist in these old Android version!"
fi

if [ ! -d "$VERIFY_DIR" ]; then
    mkdir -p "$VERIFY_DIR"
fi

echo "- Extract aautilities.sh"
unzip -o "$ZIPFILE" 'aautilities.sh' -d "$TMPDIR" >&2
if [ ! -f "$TMPDIR/aautilities.sh" ]; then
  echo "! Failed to extract aautilities.sh!"
  abort "! This zip may be corrupted!"
fi

. "$TMPDIR/aautilities.sh"

logowl "Setting up $MOD_NAME"
logowl "Version: $MOD_VER"
install_env_check
init_logowl "$LOG_DIR" > /dev/null 2>&1
clean_old_logs "$LOG_DIR" 20 > /dev/null 2>&1
show_system_info
logowl "Essential checks"
extract "$ZIPFILE" 'aautilities.sh' "$VERIFY_DIR"
extract "$ZIPFILE" 'customize.sh' "$VERIFY_DIR"
logowl "Extract module files"
extract "$ZIPFILE" 'aautilities.sh' "$MODPATH"
extract "$ZIPFILE" 'module.prop' "$MODPATH"
extract "$ZIPFILE" 'action.sh' "$MODPATH"
extract "$ZIPFILE" 'post-fs-data.sh' "$MODPATH"
extract "$ZIPFILE" 'service.sh' "$MODPATH"
extract "$ZIPFILE" 'uninstall.sh' "$MODPATH"
if [ ! -f "$CONFIG_DIR/vbmeta.conf" ]; then
    logowl "vbmeta.conf does NOT exist"
    extract "$ZIPFILE" 'vbmeta.conf' "$CONFIG_DIR"    
else
    logowl "Detect vbmeta.conf already exists"
    logowl "vbmeta.conf will NOT be overwritten"
fi
if [ -n "$VERIFY_DIR" ] && [ -d "$VERIFY_DIR" ] && [ "$VERIFY_DIR" != "/" ]; then
    rm -rf "$VERIFY_DIR"
fi
logowl "Setting permissions"
set_perm_recursive "$MODPATH" 0 0 0755 0644
logowl "Welcome to use $MOD_NAME!"
