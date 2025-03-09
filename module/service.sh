#!/system/bin/sh
MODDIR=${0%/*}

CONFIG_DIR=/data/adb/vbmetadisguiser
CONFIG_FILE="$CONFIG_DIR/vbmeta.conf"
LOG_DIR="$CONFIG_DIR/logs"
LOG_FILE="$LOG_DIR/vd_log_core_$(date +"%Y-%m-%d_%H-%M-%S").log"
MOD_NAME="$(sed -n 's/^name=\(.*\)/\1/p' "${MODDIR}/module.prop")"
MOD_AUTHOR="$(sed -n 's/^author=\(.*\)/\1/p' "${MODDIR}/module.prop")"
MOD_VER="$(sed -n 's/^version=\(.*\)/\1/p' "${MODDIR}/module.prop") ($(sed -n 's/^versionCode=\(.*\)/\1/p' "${MODDIR}/module.prop"))"

config_loader() {

    logowl "Start loading configuration"
    if [[ ! -f "$CONFIG_FILE" ]]; then
        logowl "Configuration file does not exist: $CONFIG_FILE" "ERROR"
        logowl "$MOD_NAME will use default values"
        return 1
    fi
    boot_hash=$(init_variables "boot_hash" "$CONFIG_FILE" "")
    vbmeta_size=$(init_variables "vbmeta_size" "$CONFIG_FILE" "4096")

    logowl "boot_hash: $boot_hash"
    logowl "vbmeta_size: $vbmeta_size"

    verify_variables "boot_hash" "$boot_hash" "" ""
    verify_variables "vbmeta_size" "$vbmeta_size" "^[1-9]\d*$" "4096"

}

. "$MODDIR/aautilities.sh"

init_logowl "$LOG_DIR"
install_env_check
print_line >> "$LOG_FILE"
module_intro >> "$LOG_FILE" 
logowl "Starting service.sh"
print_line >> "$LOG_FILE"
config_loader
print_line >> "$LOG_FILE"

{
    while [ "$(getprop sys.boot_completed)" != "1" ]; do
        sleep 1
    done

    resetprop -n "ro.boot.vbmeta.device_state" "locked"
    resetprop -n "ro.boot.vbmeta.avb_version" "2.0"
    resetprop -n "ro.boot.vbmeta.hash_alg" "sha256"

    if [ -s "$CONFIG_FILE" ]; then
        resetprop -n "ro.boot.vbmeta.digest" "$BOOT_HASH"
        resetprop -n "ro.boot.vbmeta.size" "$VBMETA_SIZE"
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
} &
