#!/system/bin/sh
MODDIR=${0%/*}

CONFIG_DIR=/data/adb/vbmetadisguiser
CONFIG_FILE="$CONFIG_DIR/vbmeta.conf"
LOG_DIR="$CONFIG_DIR/logs"
LOG_FILE="$LOG_DIR/vd_log_core_$(date +"%Y-%m-%d_%H-%M-%S").log"
MOD_NAME="$(sed -n 's/^name=\(.*\)/\1/p' "${MODDIR}/module.prop")"
MOD_AUTHOR="$(sed -n 's/^author=\(.*\)/\1/p' "${MODDIR}/module.prop")"
MOD_VER="$(sed -n 's/^version=\(.*\)/\1/p' "${MODDIR}/module.prop") ($(sed -n 's/^versionCode=\(.*\)/\1/p' "${MODDIR}/module.prop"))"

AVB_VERSION="2.0"
VBMETA_SIZE="4096"
BOOT_HASH="00000000000000000000000000000000"

config_loader() {

    logowl "Start loading configuration"
    
    avb_version=$(init_variables "avb_version" "$CONFIG_FILE")
    vbmeta_size=$(init_variables "vbmeta_size" "$CONFIG_FILE")
    boot_hash=$(init_variables "boot_hash" "$CONFIG_FILE")
    crypto_state=$(init_variables "crypto_state" "$CONFIG_FILE")

    verify_variables "avb_version" "$avb_version" "^[1-9][0-9]*\.[0-9]*$|^[1-9][0-9]*$"
    verify_variables "vbmeta_size" "$vbmeta_size" "^[1-9][0-9]*$"
    verify_variables "boot_hash" "$boot_hash" "^[0-9a-fA-F]{64}$"
    verify_variables "crypto_state" "$crypto_state" "^encrypted$|^unencrypted$|^unsupported$"

}

. "$MODDIR/aautilities.sh"

module_intro >> "$LOG_FILE"
init_logowl "$LOG_DIR"
logowl "Starting service.sh"
config_loader >> "$LOG_FILE"
print_line >> "$LOG_FILE"

resetprop -n "ro.boot.vbmeta.device_state" "locked"
resetprop -n "ro.boot.vbmeta.hash_alg" "sha256"

if [ -s "$CONFIG_FILE" ]; then
    resetprop -n "ro.boot.vbmeta.digest" "$BOOT_HASH"
    resetprop -n "ro.boot.vbmeta.size" "$VBMETA_SIZE"
    resetprop -n "ro.boot.vbmeta.avb_version" "$AVB_VERSION"
    if [ -n "$CRYPTO_STATE" ]; then
        resetprop -n "ro.crypto.state" "$CRYPTO_STATE"
    fi
fi

logowl "Specific variables"
print_line >> "$LOG_FILE"
logowl "ro.boot.vbmeta.device_state=$(getprop ro.boot.vbmeta.device_state)"
logowl "ro.boot.vbmeta.avb_version=$(getprop ro.boot.vbmeta.avb_version)"
logowl "ro.boot.vbmeta.hash_alg=$(getprop ro.boot.vbmeta.hash_alg)"
logowl "ro.boot.vbmeta.size=$(getprop ro.boot.vbmeta.size)"
logowl "ro.boot.vbmeta.digest=$(getprop ro.boot.vbmeta.digest)"
logowl "ro.crypto.state=$(getprop ro.crypto.state)"
print_line >> "$LOG_FILE"

logowl "Variables before case closed"
debug_print_values >> "$LOG_FILE"
logowl "service.sh case closed!"
