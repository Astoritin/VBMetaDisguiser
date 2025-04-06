#!/system/bin/sh
MODDIR=${0%/*}

CONFIG_DIR="/data/adb/vbmetadisguiser"

CONFIG_FILE="$CONFIG_DIR/vbmeta.conf"
LOG_DIR="$CONFIG_DIR/logs"
LOG_FILE="$LOG_DIR/vd_log_vbmeta_$(date +"%Y-%m-%d_%H-%M-%S").log"

MODULE_PROP="${MODDIR}/module.prop"
MOD_NAME="$(sed -n 's/^name=\(.*\)/\1/p' "$MODULE_PROP")"
MOD_AUTHOR="$(sed -n 's/^author=\(.*\)/\1/p' "$MODULE_PROP")"
MOD_VER="$(sed -n 's/^version=\(.*\)/\1/p' "$MODULE_PROP") ($(sed -n 's/^versionCode=\(.*\)/\1/p' "$MODULE_PROP"))"

TRICKY_STORE_CONFIG_FILE="/data/adb/tricky_store/security_patch.txt"

AVB_VERSION="2.0"
VBMETA_SIZE="4096"
BOOT_HASH="00000000000000000000000000000000"

debug_props_info() {

    print_line
    logowl " " "SPACE"
    logowl "ro.boot.vbmeta.device_state=$(getprop ro.boot.vbmeta.device_state)"
    logowl "ro.boot.vbmeta.avb_version=$(getprop ro.boot.vbmeta.avb_version)"
    logowl "ro.boot.vbmeta.hash_alg=$(getprop ro.boot.vbmeta.hash_alg)"
    logowl "ro.boot.vbmeta.size=$(getprop ro.boot.vbmeta.size)"
    logowl "ro.boot.vbmeta.digest=$(getprop ro.boot.vbmeta.digest)"
    logowl " " "SPACE"
    logowl "ro.crypto.state=$(getprop ro.crypto.state)"
    logowl " " "SPACE"
    logowl "ro.build.version.security_patch=$(getprop ro.build.version.security_patch)"
    logowl "ro.system.build.security_patch=$(getprop ro.system.build.security_patch)"
    logowl "ro.vendor.build.security_patch=$(getprop ro.vendor.build.security_patch)"
    logowl " " "SPACE"
    print_line

}

config_loader() {

    logowl "Loading config"
    
    avb_version=$(init_variables "avb_version" "$CONFIG_FILE")
    vbmeta_size=$(init_variables "vbmeta_size" "$CONFIG_FILE")
    boot_hash=$(init_variables "boot_hash" "$CONFIG_FILE")
    crypto_state=$(init_variables "crypto_state" "$CONFIG_FILE")

    verify_variables "avb_version" "$avb_version" "^[1-9][0-9]*\.[0-9]*$|^[1-9][0-9]*$"
    verify_variables "vbmeta_size" "$vbmeta_size" "^[1-9][0-9]*$"
    verify_variables "boot_hash" "$boot_hash" "^[0-9a-fA-F]{64}$"
    verify_variables "crypto_state" "$crypto_state" "^encrypted$|^unencrypted$|^unsupported$"

}

vbmeta_disguiser() {

    resetprop -n "ro.boot.vbmeta.device_state" "locked"
    resetprop -n "ro.boot.vbmeta.hash_alg" "sha256"

    if [ -s "$CONFIG_FILE" ]; then
        resetprop -n "ro.boot.vbmeta.digest" "$BOOT_HASH"
        resetprop -n "ro.boot.vbmeta.size" "$VBMETA_SIZE"
        resetprop -n "ro.boot.vbmeta.avb_version" "$AVB_VERSION"
    fi

}

encryption_disguiser(){

    if [ -n "$CRYPTO_STATE" ]; then
        resetprop -n "ro.crypto.state" "$CRYPTO_STATE"
    fi

}

module_status_update() {
    
    logowl "Updating module status"
    
    vbmeta_version=$(getprop 'ro.boot.vbmeta.avb_version')
    vbmeta_digest=$(getprop 'ro.boot.vbmeta.digest' | cut -c1-18 | tr '[:lower:]' '[:upper:]')
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
        desc_vbmeta="✅VBMeta Hash: $vbmeta_digest ($vbmeta_hash_alg)"
    fi
    
    desc_avb="✅AVB ${vbmeta_version:-N/A} (${device_state:-N/A})"

    if [ "$crypto_state" = "encrypted" ]; then
        desc_crypto="🔒"
    elif [ "$crypto_state" = "unencrypted" ]; then
        desc_crypto="🔓"
    elif [ "$crypto_state" = "unsupported" ]; then
        desc_crypto="❌"
    fi
    desc_crypto="${desc_crypto}Data partition: $crypto_state"

    if [ ! -e "$TRICKY_STORE_CONFIG_FILE" ] && [ -e "$CONFIG_FILE" ]; then
        desc_ts_sp="❓Security patch config does NOT exist"
    elif [ ! -f "$TRICKY_STORE_CONFIG_FILE" ] && [ -f "$CONFIG_FILE" ]; then
        desc_ts_sp="❌Security patch config abnormal"
    elif [ ! -s "$TRICKY_STORE_CONFIG_FILE" ] && [ -s "$CONFIG_FILE" ]; then
        desc_ts_sp="❓Security patch: N/A"
    else
        desc_ts_sp="✅Security patch: $security_patch"
    fi

    DESCRIPTION="[${desc_avb}, ${desc_vbmeta}, ${desc_ts_sp}, ${desc_crypto}] A module to disguise the props of vbmeta, security patch date and encryption status✨"

    update_module_description "$DESCRIPTION" "$MODULE_PROP"

} >> "$LOG_FILE" 2>&1

. "$MODDIR/aautilities.sh"

init_logowl "$LOG_DIR"
module_intro >> "$LOG_FILE"
show_system_info
print_line
logowl "Starting service.sh"
print_line
config_loader
logowl "Before"
debug_props_info
vbmeta_disguiser
encryption_disguiser
module_status_update
logowl " "
print_line
logowl "After"
debug_props_info
logowl "service.sh case closed!"
