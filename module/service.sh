#!/system/bin/sh
MODDIR=${0%/*}

CONFIG_DIR="/data/adb/vbmetadisguiser"

CONFIG_FILE="$CONFIG_DIR/vbmeta.conf"
LOG_DIR="$CONFIG_DIR/logs"
LOG_FILE="$LOG_DIR/vd_core_vm_$(date +"%Y-%m-%d_%H-%M-%S").log"

CONFIG_FILE_OLD="$LOG_DIR/vbmeta_old.conf"

MODULE_PROP="${MODDIR}/module.prop"
MOD_NAME="$(sed -n 's/^name=\(.*\)/\1/p' "$MODULE_PROP")"
MOD_AUTHOR="$(sed -n 's/^author=\(.*\)/\1/p' "$MODULE_PROP")"
MOD_VER="$(sed -n 's/^version=\(.*\)/\1/p' "$MODULE_PROP") ($(sed -n 's/^versionCode=\(.*\)/\1/p' "$MODULE_PROP"))"
MOD_ROOT_DIR="$(dirname "$MODDIR")"

MOD_INTRO="Disguise the properties of vbmeta, security patch date and encryption status."

MOD_DESC_OLD="$(sed -n 's/^description=\(.*\)/\1/p' "$MODULE_PROP")"

TRICKY_STORE_CONFIG_FILE="/data/adb/tricky_store/security_patch.txt"
SHAMIKO_DIR="${MOD_ROOT_DIR}/zygisk_shamiko"
SENSITIVE_PROPS_DIR="${MOD_ROOT_DIR}/sensitive_props"

UPDATE_REALTIME=true
UPDATE_PERIOD=60

AVB_VERSION="2.0"
VBMETA_SIZE="4096"
BOOT_HASH="00000000000000000000000000000000"

config_loader() {

    logowl "Load config"
    
    update_realtime=$(get_config_var "update_realtime" "$CONFIG_FILE")
    update_period=$(get_config_var "update_period" "$CONFIG_FILE")
    avb_version=$(get_config_var "avb_version" "$CONFIG_FILE")
    vbmeta_size=$(get_config_var "vbmeta_size" "$CONFIG_FILE")
    boot_hash=$(get_config_var "boot_hash" "$CONFIG_FILE")
    crypto_state=$(get_config_var "crypto_state" "$CONFIG_FILE")

    verify_var "update_realtime" "$update_realtime" "^(true|false)$"
    verify_var "update_period" "$update_period" "^[1-9][0-9]*$"
    verify_var "avb_version" "$avb_version" "^[1-9][0-9]*\.[0-9]*$|^[1-9][0-9]*$"
    verify_var "vbmeta_size" "$vbmeta_size" "^[1-9][0-9]*$"
    verify_var "boot_hash" "$boot_hash" "^[0-9a-fA-F]+$"
    verify_var "crypto_state" "$crypto_state" "^encrypted$|^unencrypted$|^unsupported$"

}

encryption_disguiser(){

    [ -n "$CRYPTO_STATE" ] && resetprop -n "ro.crypto.state" "$CRYPTO_STATE"

}

module_status_update() {

    desc_max=3
    update_count=0
    
    vbmeta_version=$(getprop 'ro.boot.vbmeta.avb_version')
    vbmeta_digest=$(getprop 'ro.boot.vbmeta.digest' | cut -c1-8 | tr '[:lower:]' '[:upper:]')
    ellipsis="[..]"
    vbmeta_digest="${vbmeta_digest}${ellipsis}"
    vbmeta_hash_alg=$(getprop 'ro.boot.vbmeta.hash_alg' | tr '[:lower:]' '[:upper:]')
    vbmeta_size=$(getprop 'ro.boot.vbmeta.size')
    device_state=$(getprop 'ro.boot.vbmeta.device_state')
    crypto_state=$(getprop 'ro.crypto.state')
    security_patch=$(getprop 'ro.build.version.security_patch')

    if [ -z "$vbmeta_digest" ] || echo "$vbmeta_digest" | grep -qE '^0+$'; then
        desc_vbmeta="❓VBMeta: N/A"
    else
        desc_vbmeta="✅VBMeta: $vbmeta_digest ($vbmeta_hash_alg)"
        update_count=$((update_count + 1))
    fi
    
    desc_avb="AVB ${vbmeta_version:-N/A} (${device_state:-N/A})"

    [ "$crypto_state" = "encrypted" ] && desc_crypto="🔒"
    [ "$crypto_state" = "unencrypted" ] && desc_crypto="🔓"
    [ "$crypto_state" = "unsupported" ] && desc_crypto="❌"
    [ -n "$desc_crypto" ] && update_count=$((update_count + 1))
    desc_crypto="${desc_crypto}Data: $crypto_state"

    if [ ! -e "$TRICKY_STORE_CONFIG_FILE" ] && [ ! -e "$CONFIG_FILE" ]; then
        desc_ts_sp="❓Security patch config does NOT exist"
    elif [ ! -f "$TRICKY_STORE_CONFIG_FILE" ] && [ ! -f "$CONFIG_FILE" ]; then
        desc_ts_sp="❌Security patch config abnormal"
    elif [ ! -s "$TRICKY_STORE_CONFIG_FILE" ] && [ ! -s "$CONFIG_FILE" ]; then
        desc_ts_sp="❓Security patch: N/A"
    else
        desc_ts_sp="✅Security patch: $security_patch"
        update_count=$((update_count + 1))
    fi

    desc_active=""
    if [ "$update_count" -eq "$desc_max" ]; then
        desc_active="✅All Done."
    elif [ "$update_count" -gt 0 ]; then
        desc_active="✅Done."
    fi
    
    if [ -n "$desc_active" ]; then
        if [ $((RANDOM % 2)) -eq 0 ]; then
            DESCRIPTION="[$desc_active $desc_vbmeta, $desc_avb, $desc_ts_sp, $desc_crypto] $MOD_INTRO"
        else
            DESCRIPTION="[$desc_active $desc_vbmeta, $desc_avb, $desc_ts_sp, $desc_crypto] $MOD_INTRO"
        fi
    else
        DESCRIPTION="[❌No effect. Maybe something went wrong?] $MOD_INTRO"
    fi

    update_config_var "description" "$DESCRIPTION" "$MODULE_PROP"

}

soft_bootloader_spoof() {

    if [ -e "$SHAMIKO_DIR" ] || [ -e "$SENSITIVE_PROPS_DIR" ]; then
        return 0
    fi

    check_before_resetprop "ro.boot.vbmeta.device_state" "locked"
    check_before_resetprop "ro.boot.verifiedbootstate" "green"
    check_before_resetprop "ro.boot.flash.locked" "1"
    check_before_resetprop "ro.boot.veritymode" "enforcing"
    check_before_resetprop "ro.boot.warranty_bit" "0"
    check_before_resetprop "ro.warranty_bit" "0"
    check_before_resetprop "ro.debuggable" "0"
    check_before_resetprop "ro.force.debuggable" "0"
    check_before_resetprop "ro.secure" "1"
    check_before_resetprop "ro.adb.secure" "1"
    check_before_resetprop "ro.build.type" "user"
    check_before_resetprop "ro.build.tags" "release-keys"
    check_before_resetprop "ro.vendor.boot.warranty_bit" "0"
    check_before_resetprop "ro.vendor.warranty_bit" "0"
    check_before_resetprop "vendor.boot.vbmeta.device_state" "locked"
    check_before_resetprop "vendor.boot.verifiedbootstate" "green"

    check_before_resetprop "sys.oem_unlock_allowed" "0"
    check_before_resetprop "ro.oem_unlock_supported" "0"

    check_before_resetprop "ro.boot.realmebootstate" "green"
    check_before_resetprop "ro.boot.realme.lockstate" "1"

    check_before_resetprop "ro.secureboot.lockstate" "locked"

    check_before_resetprop "init.svc.flash_recovery" "stopped"

    find_keyword_before_resetprop "ro.bootmode" "recovery" "unknown"
    find_keyword_before_resetprop "ro.boot.bootmode" "recovery" "unknown"
    find_keyword_before_resetprop "vendor.boot.bootmode" "recovery" "unknown"

}

debug_props_info() {

    print_line "45" "-"
    logowl "Security Patch date properties"
    print_line "45" " "
    fetch_prop "ro.build.version.security_patch"
    fetch_prop "ro.system.build.security_patch"
    fetch_prop "ro.vendor.build.security_patch"
    print_line "45" " "
    logowl "VBMeta partition properties"
    print_line "45" " "
    fetch_prop "ro.boot.vbmeta.device_state"
    fetch_prop "ro.boot.vbmeta.avb_version"
    fetch_prop "ro.boot.vbmeta.hash_alg"
    fetch_prop "ro.boot.vbmeta.size"
    fetch_prop "ro.boot.vbmeta.digest"
    print_line "45" " "
    logowl "Data partition properties"
    print_line "45" " "
    fetch_prop "ro.crypto.state"
    print_line "45" "-"

}

vbmeta_disguiser() {

    resetprop "ro.boot.vbmeta.device_state" "locked"
    resetprop "ro.boot.vbmeta.hash_alg" "sha256"

    if [ -s "$CONFIG_FILE" ]; then
        resetprop "ro.boot.vbmeta.digest" "$BOOT_HASH"
        resetprop "ro.boot.vbmeta.size" "$VBMETA_SIZE"
        resetprop "ro.boot.vbmeta.avb_version" "$AVB_VERSION"
    fi

}

. "$MODDIR/aa-util.sh"

logowl_init "$LOG_DIR"
module_intro >> "$LOG_FILE"
show_system_info
print_line
logowl "Start service.sh"
print_line
[ -f "$CONFIG_FILE" ] && cp "$CONFIG_FILE" "$CONFIG_FILE_OLD"
config_loader
vbmeta_disguiser && logowl "Disguise VBMeta partition properties"
encryption_disguiser && logowl "Disguise Data partition encryption property"
soft_bootloader_spoof && logowl "Reset specific bootloader properties"
module_status_update && logowl "Update module description"
logowl "Check properties"
debug_props_info
logowl "service.sh case closed!"

{

    MOD_REAL_TIME_DESC=""
    while true; do
        
        [ "$UPDATE_REALTIME" = false ] && exit 0

        [ ! -f "$CONFIG_FILE" ] && exit 1

        if [ ! -f "$CONFIG_FILE_OLD" ]; then
            [ -f "$CONFIG_FILE" ] && cp "$CONFIG_FILE" "$CONFIG_FILE_OLD"
        elif ! file_compare "$CONFIG_FILE_OLD" "$CONFIG_FILE"; then
            print_line "45" "*"
            logowl "Detect changes in $CONFIG_FILE"
            logowl "Timestamp: $(date +"%Y-%m-%d %H:%M:%S")"
            logowl "Current update period: ${UPDATE_PERIOD}s"
            config_loader
            vbmeta_disguiser
            encryption_disguiser
            module_status_update
            debug_props_info
            [ -f "$CONFIG_FILE" ] && cp "$CONFIG_FILE" "$CONFIG_FILE_OLD"
        fi

        if [ -f "$MODDIR/update" ]; then
            MOD_CURRENT_STATUS="update"
        elif [ -f "$MODDIR/remove" ]; then
            MOD_CURRENT_STATUS="remove"
        elif [ -f "$MODDIR/disable" ]; then
            MOD_CURRENT_STATUS="disable"
        else
            MOD_CURRENT_STATUS="enable"
        fi

        if [ "$MOD_CURRENT_STATUS" = "update" ]; then
            logowl "Detect update status"
            logowl "Exit background task"
            exit 0
        elif [ "$MOD_CURRENT_STATUS" = "enable" ]; then
            module_status_update
        fi
        sleep "$UPDATE_PERIOD"
    done

} &
