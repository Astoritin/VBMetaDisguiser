#!/system/bin/sh
SKIPUNZIP=1

CONFIG_DIR=/data/adb/vbmetadisguiser
LOG_DIR="$CONFIG_DIR/logs"
CONFIG_FILE="$CONFIG_DIR/vbmeta.conf"

VERIFY_DIR="$TMPDIR/.aa_verify"

MOD_NAME="$(grep_prop name "${TMPDIR}/module.prop")"
MOD_VER="$(grep_prop version "${TMPDIR}/module.prop") ($(grep_prop versionCode "${TMPDIR}/module.prop"))"
MOD_INTRO="Disguise the properties of vbmeta, security patch date and encryption status."

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
logowl "Extract module files"
extract "$ZIPFILE" 'aa-util.sh' "$MODPATH"
extract "$ZIPFILE" 'module.prop' "$MODPATH"
extract "$ZIPFILE" 'action.sh' "$MODPATH"
extract "$ZIPFILE" 'post-fs-data.sh' "$MODPATH"
extract "$ZIPFILE" 'service.sh' "$MODPATH"
extract "$ZIPFILE" 'uninstall.sh' "$MODPATH"
if [ ! -f "$CONFIG_FILE" ]; then
    logowl "vbmeta.conf does NOT exist"
    extract "$ZIPFILE" 'vbmeta.conf' "$CONFIG_DIR"    
else
    logowl "vbmeta.conf already exists"
    check_props_slay=$(grep_config_var "props_slay" "$CONFIG_FILE")
    check_props_list=$(grep_config_var "props_list" "$CONFIG_FILE")
    check_addon_d_slay=$(grep_config_var "addon_d_slay" "$CONFIG_FILE")
    check_install_recovery_slay=$(grep_config_var "install_recovery_slay" "$CONFIG_FILE")
    if [ -z "$check_props_slay" ]; then
      logowl "Append new config to vbmeta.conf"
        echo -e "\n# Behaviors of Properties Slayer\n
props_slay=false\n" >> "$CONFIG_FILE"
    fi
    if [ -z "$check_props_list" ]; then
        echo -e 'props_list="persist.sys.spoof.gms
persist.sys.pihooks.security_pa
persist.sys.pihooks.first_api_l
persist.sys.pihooks.disable.gms
persist.sys.pihooks.disable.gms_props
persist.sys.pihooks.disable.gms_key_attestation_block
persist.sys.pihooks_ID
persist.sys.pihooks_BRAND
persist.sys.pihooks_DEVICE
persist.sys.pihooks_DEVICE_INIT
persist.sys.pihooks_PRODUCT
persist.sys.pihooks_FINGERPRINT
persist.sys.pihooks_MANUFACTURE
persist.sys.pihooks_SECURITY_PA
persist.sys.pihooks_mainline_BR
persist.sys.pihooks_mainline_MO
persist.sys.pihooks_mainline_DE
persist.sys.pihooks_mainline_PR
persist.sys.pihooks_mainline_FI
persist.sys.pihooks_mainline_MA
persist.sys.pixelprops.pi
persist.sys.pixelprops.all
persist.sys.pixelprops.gms
persist.sys.pixelprops.gapps
persist.sys.pixelprops.google
persist.sys.pixelprops.gphotos
persist.sys.spoof.gms
persist.sys.entryhooks_enabled"\n' >> "$CONFIG_FILE"
    fi
    if [ -z "$check_addon_d_slay" ]; then
        echo -e "addon_d_slay=false\n" >> "$CONFIG_FILE"
    fi
    if [ -z "$check_install_recovery_slay" ]; then
        echo -e "install_recovery_slay=false\n" >> "$CONFIG_FILE"
    fi
    [ -n "$check_props_slay" ] && [ -n "$check_props_list" ] && [ -n "$check_addon_d_slay" ] && [ -n "$check_install_recovery_slay" ] && logowl "vbmeta.conf will NOT be overwritten"
fi
rm -rf "$VERIFY_DIR"
mv "$LOG_DIR/slain_props.prop" "$CONFIG_DIR/slain_props.prop"
logowl "Set permission"
set_permission_recursive "$MODPATH" 0 0 0755 0644
logowl "Welcome to use $MOD_NAME!"
DESCRIPTION="[✨Reboot to take effect.] $MOD_INTRO"
update_config_var "description" "$DESCRIPTION" "$MODPATH/module.prop"
