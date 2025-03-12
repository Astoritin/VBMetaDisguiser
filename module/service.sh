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

    verify_variables "avb_version" "$avb_version" "^[1-9][0-9]*\.[0-9]*$|^[1-9][0-9]*$"
    verify_variables "vbmeta_size" "$vbmeta_size" "^[1-9][0-9]*$"
    verify_variables "boot_hash" "$boot_hash" "^[0-9a-fA-F]{64}$"

}

. "$MODDIR/aautilities.sh"

module_intro >> "$LOG_FILE"
init_logowl "$LOG_DIR"
logowl "Starting service.sh"
config_loader >> "$LOG_FILE"
print_line >> "$LOG_FILE"

resetprop "ro.boot.vbmeta.device_state" "locked"
resetprop "ro.boot.vbmeta.hash_alg" "sha256"

if [ -s "$CONFIG_FILE" ]; then
    resetprop "ro.boot.vbmeta.digest" "$BOOT_HASH"
    resetprop "ro.boot.vbmeta.size" "$VBMETA_SIZE"
    resetprop "ro.boot.vbmeta.avb_version" "$AVB_VERSION"
fi

print_line >> "$LOG_FILE"
logowl "Result:"
logowl "ro.boot.vbmeta.device_state=$(getprop ro.boot.vbmeta.device_state)"
logowl "ro.boot.vbmeta.avb_version=$(ro.boot.vbmeta.avb_version)"
logowl "ro.boot.vbmeta.hash_alg=$(ro.boot.vbmeta.hash_alg)"
logowl "ro.boot.vbmeta.size=$(ro.boot.vbmeta.size)"
logowl "ro.boot.vbmeta.digest=$(ro.boot.vbmeta.digest)"
print_line >> "$LOG_FILE"

logowl "Variables before case closed"
debug_print_values >> "$LOG_FILE"
logowl "service.sh case closed!"
