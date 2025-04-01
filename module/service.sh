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

}

encryption_disguiser(){

    if [ -n "$CRYPTO_STATE" ]; then
        resetprop -n "ro.crypto.state" "$CRYPTO_STATE"
    fi

}

module_status_update() {
    # module_status_update: a function to update module status according to the result in function vbmeta disguiser
    
    logowl "Updating module status..."
    
    vbmeta_version=$(getprop 'ro.boot.vbmeta.avb_version' 2>/dev/null)
    vbmeta_digest=$(getprop 'ro.boot.vbmeta.digest' 2>/dev/null)
    vbmeta_hash_alg=$(getprop 'ro.boot.vbmeta.hash_alg' 2>/dev/null)
    vbmeta_size=$(getprop 'ro.boot.vbmeta.size' 2>/dev/null)
    device_state=$(getprop 'ro.boot.vbmeta.device_state' 2>/dev/null)
    crypto_state=$(getprop 'ro.crypto.state' 2>/dev/null)
    security_patch=$(getprop 'ro.build.version.security_patch' 2>/dev/null)
    vendor_patch=$(getprop 'ro.vendor.build.security_patch' 2>/dev/null)
    system_patch=$(getprop 'ro.system.build.security_patch' 2>/dev/null)

    DESCRIPTION="[😋Enabled. ✅AVB version: ${vbmeta_version:-N/A}, boot hash: ${vbmeta_digest:-N/A} (${vbmeta_hash_alg:-N/A}), VBMeta size: ${vbmeta_size:-N/A}, lock status: ${device_state:-N/A}, encryption: ${crypto_state:-N/A}, security patches: $security_patch / $vendor_patch / $system_patch ⭐Root: $ROOT_SOL] A module to disguise the props of vbmeta and encryption status✨"
    
    update_module_description "$DESCRIPTION" "$MODULE_PROP" && logowl "Status updated: $DESCRIPTION"

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
module_status_update
logowl " "
print_line
logowl "After"
debug_props_info
# logowl "Variables before case closed"
# debug_print_values >> "$LOG_FILE"
logowl "service.sh case closed!"
