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

AVB_VERSION="2.0"
VBMETA_SIZE="4096"
BOOT_HASH="00000000000000000000000000000000"

VBMETA_DISGUISE_STATUS=false
ENCRYPTION_DISGUISE_STATUS=false

debug_props_info() {

    print_line
    logowl " " "SPACE"
    logowl "ro.boot.vbmeta.device_state=$(getprop ro.boot.vbmeta.device_state)" "SPACE"
    logowl "ro.boot.vbmeta.avb_version=$(getprop ro.boot.vbmeta.avb_version)" "SPACE"
    logowl "ro.boot.vbmeta.hash_alg=$(getprop ro.boot.vbmeta.hash_alg)" "SPACE"
    logowl "ro.boot.vbmeta.size=$(getprop ro.boot.vbmeta.size)" "SPACE"
    logowl "ro.boot.vbmeta.digest=$(getprop ro.boot.vbmeta.digest)" "SPACE"
    logowl " " "SPACE"
    print_line

}

config_loader() {
    # config_loader: a function to load the config file saved in $CONFIG_FILE
    # the format of $CONFIG_FILE: value=key, one key-value pair per line

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

    VBMETA_DISGUISE_STATUS=true

}

encryption_disguiser(){

    if [ -n "$CRYPTO_STATE" ]; then
        resetprop -n "ro.crypto.state" "$CRYPTO_STATE"
    fi

    ENCRYPTION_DISGUISE_STATUS=true

}

module_status_update() {
    # module_status_update: a function to update module status according to the result in function vbmeta disguiser

    logowl "Updating module status"

    OLD_DESC=$(sed -n 's/^description=//p' "$MODULE_PROP")

    if [ "$VBMETA_DISGUISE_STATUS" = "true" ]; then
        APPEND_DESC_VBMETA="✅VBMeta status disguised."
    else
        APPEND_DESC_VBMETA="❌VBMeta status NOT disguise yet!"
    fi

    if [ "$ENCRYPTION_DISGUISE_STATUS" = "true" ]; then
        APPEND_DESC_ENCRYPTION="✅Encryption status disguised."
    else
        APPEND_DESC_ENCRYPTION="❌Encryption status NOT disguise yet!"
    fi

    APPEND_DESC="${APPEND_DESC_VBMETA} ${APPEND_DESC_ENCRYPTION}"
    NEW_DESC=$(echo "$OLD_DESC" | sed "s/\[\([^]]*\)\./\[\1.${APPEND_DESC}/")
    update_module_description "$NEW_DESC" "$MODULE_PROP"

}

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
logowl " "
print_line
logowl "After"
debug_props_info
# logowl "Variables before case closed"
# debug_print_values >> "$LOG_FILE"
logowl "service.sh case closed!"
