#!/system/bin/sh
MODDIR=${0%/*}

CONFIG_DIR="/data/adb/vbmetadisguiser"
DEBUG=false

CONFIG_FILE="$CONFIG_DIR/vbmeta.conf"
LOG_DIR="$CONFIG_DIR/logs"
LOG_FILE="$LOG_DIR/vd_core_vb_$(date +"%Y-%m-%d_%H-%M-%S").log"

MODULE_PROP="${MODDIR}/module.prop"
MOD_NAME="$(sed -n 's/^name=\(.*\)/\1/p' "$MODULE_PROP")"
MOD_AUTHOR="$(sed -n 's/^author=\(.*\)/\1/p' "$MODULE_PROP")"
MOD_VER="$(sed -n 's/^version=\(.*\)/\1/p' "$MODULE_PROP") ($(sed -n 's/^versionCode=\(.*\)/\1/p' "$MODULE_PROP"))"

TRICKY_STORE_CONFIG_FILE="/data/adb/tricky_store/security_patch.txt"

AVB_VERSION="2.0"
VBMETA_SIZE="8192"
BOOT_HASH="00000000000000000000000000000000"

debug_props_info() {

    print_line
    debug_get_prop "ro.boot.vbmeta.device_state"
    debug_get_prop "ro.boot.vbmeta.avb_version"
    debug_get_prop "ro.boot.vbmeta.hash_alg"
    debug_get_prop "ro.boot.vbmeta.size"
    debug_get_prop "ro.boot.vbmeta.digest"
    print_line
    debug_get_prop "ro.crypto.state"
    print_line
    debug_get_prop "ro.build.version.security_patch"
    debug_get_prop "ro.system.build.security_patch"
    debug_get_prop "ro.vendor.build.security_patch"
    print_line

}

config_loader() {

    logowl "Load config"
    
    debug=$(init_variables "debug" "$CONFIG_FILE")
    avb_version=$(init_variables "avb_version" "$CONFIG_FILE")
    vbmeta_size=$(init_variables "vbmeta_size" "$CONFIG_FILE")
    boot_hash=$(init_variables "boot_hash" "$CONFIG_FILE")
    crypto_state=$(init_variables "crypto_state" "$CONFIG_FILE")

    verify_variables "debug" "$debug" "^(true|false)$"
    verify_variables "avb_version" "$avb_version" "^[1-9][0-9]*\.[0-9]*$|^[1-9][0-9]*$"
    verify_variables "vbmeta_size" "$vbmeta_size" "^[1-9][0-9]*$"
    verify_variables "boot_hash" "$boot_hash" "^[0-9a-fA-F]{64}$"
    verify_variables "crypto_state" "$crypto_state" "^encrypted$|^unencrypted$|^unsupported$"

}

vbmeta_disguiser() {

    logowl "Disguise VBMeta partition status"

    resetprop -n "ro.boot.vbmeta.device_state" "locked"
    resetprop -n "ro.boot.vbmeta.hash_alg" "sha256"

    if [ -s "$CONFIG_FILE" ]; then
        resetprop -n "ro.boot.vbmeta.digest" "$BOOT_HASH"
        resetprop -n "ro.boot.vbmeta.size" "$VBMETA_SIZE"
        resetprop -n "ro.boot.vbmeta.avb_version" "$AVB_VERSION"
    fi

}

encryption_disguiser(){

    logowl "Disguise Data partition encryption state"

    [ -n "$CRYPTO_STATE" ] && resetprop -n "ro.crypto.state" "$CRYPTO_STATE"

}

module_status_update() {

    logowl "Update module status"

    update_count=0    
    vbmeta_version=$(getprop 'ro.boot.vbmeta.avb_version')
    vbmeta_digest=$(getprop 'ro.boot.vbmeta.digest' | cut -c1-12 | tr '[:lower:]' '[:upper:]')
    ellipsis="(...)"
    vbmeta_digest="${vbmeta_digest}${ellipsis}"
    vbmeta_hash_alg=$(getprop 'ro.boot.vbmeta.hash_alg' | tr '[:lower:]' '[:upper:]')
    vbmeta_size=$(getprop 'ro.boot.vbmeta.size')
    device_state=$(getprop 'ro.boot.vbmeta.device_state')
    crypto_state=$(getprop 'ro.crypto.state')
    security_patch=$(getprop 'ro.build.version.security_patch')

    if [ -z "$vbmeta_digest" ] || echo "$vbmeta_digest" | grep -qE '^0+$'; then
        desc_vbmeta="❓VBMeta Hash: N/A"
    else
        desc_vbmeta="VBMeta Hash: $vbmeta_digest ($vbmeta_hash_alg)"
        update_count=$((update_count + 1))
    fi
    
    desc_avb="AVB ${vbmeta_version:-N/A} (${device_state:-N/A})"

    [ "$crypto_state" = "encrypted" ] && desc_crypto="🔒"
    [ "$crypto_state" = "unencrypted" ] && desc_crypto="🔓"
    [ "$crypto_state" = "unsupported" ] && desc_crypto="❌"
    [ -n "$desc_crypto" ] && update_count=$((update_count + 1))
    desc_crypto="${desc_crypto}Data partition: $crypto_state"

    if [ ! -e "$TRICKY_STORE_CONFIG_FILE" ] && [ ! -e "$CONFIG_FILE" ]; then
        desc_ts_sp="❓Security patch config does NOT exist"
    elif [ ! -f "$TRICKY_STORE_CONFIG_FILE" ] && [ ! -f "$CONFIG_FILE" ]; then
        desc_ts_sp="❌Security patch config abnormal"
    elif [ ! -s "$TRICKY_STORE_CONFIG_FILE" ] && [ ! -s "$CONFIG_FILE" ]; then
        desc_ts_sp="❓Security patch: N/A"
    else
        desc_ts_sp="Security patch: $security_patch"
        update_count=$((update_count + 1))
    fi

    desc_active=""
    if [ "$update_count" -gt 0 ]; then
        desc_active="✅Done."
    else
        desc_active="❌No effect."
    fi
    
    [ -n "$desc_active" ] && DESCRIPTION="[$desc_active $desc_vbmeta, $desc_avb, $desc_ts_sp, $desc_crypto] A module to disguise the props of vbmeta, security patch date and encryption status."
    [ -z "$desc_active" ] && DESCRIPTION="[$desc_vbmeta, $desc_avb, $desc_ts_sp, $desc_crypto] A module to disguise the props of vbmeta, security patch date and encryption status."
    [ -n "$DESCRIPTION" ] && update_config_value "description" "$DESCRIPTION" "$MODULE_PROP"

} >> "$LOG_FILE" 2>&1

. "$MODDIR/aautilities.sh"

init_logowl "$LOG_DIR"
module_intro >> "$LOG_FILE"
show_system_info
print_line
logowl "Start service.sh"
print_line
config_loader
logowl "Before"
debug_props_info
vbmeta_disguiser
encryption_disguiser
module_status_update
print_line
logowl "After"
debug_props_info
logowl "service.sh case closed!"
