#!/system/bin/sh
SKIPUNZIP=1

CONFIG_DIR=/data/adb/boothashdisguiser
LOG_DIR="$CONFIG_DIR/logs"
VERIFY_DIR="$TMPDIR/.aa_bhd_verify"

MOD_NAME="$(grep_prop name "${TMPDIR}/module.prop")"
MOD_VER="$(grep_prop version "${TMPDIR}/module.prop") ($(grep_prop versionCode "${TMPDIR}/module.prop"))"

if [ ! -d "$LOG_DIR" ]; then
  echo "- $LOG_DIR does not exist"
  mkdir -p "$LOG_DIR" || abort "! Failed to create $LOG_DIR!"
  echo "- Created $LOG_DIR"
fi

echo "- Extract aautilities.sh"
unzip -o "$ZIPFILE" 'aautilities.sh' -d "$TMPDIR" >&2
if [ ! -f "$TMPDIR/aautilities.sh" ]; then
  echo "! Failed to extract aautilities.sh!"
  abort "! This zip may be corrupted!"
fi
. "$TMPDIR/aautilities.sh"

module_install_proc(){
  echo "- Setting up $MOD_NAME"
  echo "- Version: $MOD_VER"

  if [ "$API" -lt 27 ]; then
    echo "! Android version is lower than 8(oreo)!"
    about "$MOD_NAME does not support Android 8-!"
  fi

  echo "- Extract module file(s)"
  extract "$ZIPFILE" 'aautilities.sh' "$VERIFY_DIR"
  extract "$ZIPFILE" 'customize.sh' "$VERIFY_DIR"
  extract "$ZIPFILE" 'module.prop' "$MODPATH"
  extract "$ZIPFILE" 'service.sh' "$MODPATH"
  extract "$ZIPFILE" 'uninstall.sh' "$MODPATH"
  if [ ! -d "$CONFIG_DIR" ]; then
    mkdir -p "$CONFIG_DIR" || abort "! Failed to create directory: $CONFIG_DIR"
  fi
  if [ ! -f "$CONFIG_DIR/hash.info" ]; then
    echo "- hash.info does not exist"
    extract "$ZIPFILE" 'hash.info' "$TMPDIR"
    mv "$TMPDIR/hash.info" "$CONFIG_DIR/hash.info" || abort "! Failed to create hash.info!"
    echo "- Created hash.info"
    echo "- PLEASE COPY BOOT HASH INTO THE FILE: $CONFIG_DIR/hash.info !"
    echo "- AND THEN REBOOT TO TAKE EFFECT!"
  else
    echo "- Detect hash.info already existed"
    echo "- Skip overwriting hash.info"
  fi
}

show_system_info
install_env_check
module_install_proc
set_module_files_perm
echo "- Welcome to use ${MOD_NAME}!"
