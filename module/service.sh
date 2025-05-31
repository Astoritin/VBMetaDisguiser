#!/system/bin/sh
MODDIR=${0%/*}

CONFIG_DIR="/data/adb/vbmetadisguiser"

CONFIG_FILE="$CONFIG_DIR/vbmeta.conf"
LOG_DIR="$CONFIG_DIR/logs"
LOG_FILE="$LOG_DIR/vd_core_b_$(date +"%Y-%m-%d_%H-%M-%S").log"

CONFIG_FILE_OLD="$LOG_DIR/vbmeta_old.conf"

MODULE_PROP="${MODDIR}/module.prop"
MOD_NAME="$(sed -n 's/^name=\(.*\)/\1/p' "$MODULE_PROP")"
MOD_AUTHOR="$(sed -n 's/^author=\(.*\)/\1/p' "$MODULE_PROP")"
MOD_VER="$(sed -n 's/^version=\(.*\)/\1/p' "$MODULE_PROP") ($(sed -n 's/^versionCode=\(.*\)/\1/p' "$MODULE_PROP"))"
MOD_ROOT_DIR="$(dirname "$MODDIR")"

MOD_INTRO="A Magisk module to disguise the props of vbmeta, security patch date and encryption status."

MOD_DESC_OLD="$(sed -n 's/^description=\(.*\)/\1/p' "$MODULE_PROP")"

TRICKY_STORE_CONFIG_FILE="/data/adb/tricky_store/security_patch.txt"
SHAMIKO_DIR="${MOD_ROOT_DIR}/zygisk_shamiko"
SENSITIVE_PROPS_DIR="${MOD_ROOT_DIR}/sensitive_props"

UPDATE_REALTIME=true
UPDATE_PERIOD=60

AVB_VERSION="2.0"
VBMETA_SIZE="4096"
BOOT_HASH="00000000000000000000000000000000"

get_from_resetprop() {
    prop_name=$1
    prop_current_value=$(resetprop "$prop_name")

    [ -n "$prop_current_value" ] && logowl "$prop_name=$prop_current_value" 

}

debug_props_info() {

    print_line
    logowl "Security Patch date properties"
    print_line
    get_from_resetprop "ro.build.version.security_patch"
    get_from_resetprop "ro.system.build.security_patch"
    get_from_resetprop "ro.vendor.build.security_patch"
    print_line
    logowl "VBMeta partition properties"
    print_line
    get_from_resetprop "ro.boot.vbmeta.device_state"
    get_from_resetprop "ro.boot.vbmeta.avb_version"
    get_from_resetprop "ro.boot.vbmeta.hash_alg"
    get_from_resetprop "ro.boot.vbmeta.size"
    get_from_resetprop "ro.boot.vbmeta.digest"
    print_line
    logowl "Data partition properties"
    print_line
    get_from_resetprop "ro.crypto.state"
    print_line

}

config_loader() {

    logowl "Load config"
    
    update_realtime=$(init_variables "update_realtime" "$CONFIG_FILE")
    update_period=$(init_variables "update_period" "$CONFIG_FILE")
    avb_version=$(init_variables "avb_version" "$CONFIG_FILE")
    vbmeta_size=$(init_variables "vbmeta_size" "$CONFIG_FILE")
    boot_hash=$(init_variables "boot_hash" "$CONFIG_FILE")
    crypto_state=$(init_variables "crypto_state" "$CONFIG_FILE")

    verify_variables "update_realtime" "$update_realtime" "^(true|false)$"
    verify_variables "update_period" "$update_period" "^[1-9][0-9]*$"
    verify_variables "avb_version" "$avb_version" "^[1-9][0-9]*\.[0-9]*$|^[1-9][0-9]*$"
    verify_variables "vbmeta_size" "$vbmeta_size" "^[1-9][0-9]*$"
    verify_variables "boot_hash" "$boot_hash" "^[0-9a-fA-F]+$"
    verify_variables "crypto_state" "$crypto_state" "^encrypted$|^unencrypted$|^unsupported$"

}

vbmeta_disguiser() {

    check_before_resetprop "ro.boot.vbmeta.device_state" "locked"
    check_before_resetprop "ro.boot.vbmeta.hash_alg" "sha256"

    if [ -s "$CONFIG_FILE" ]; then
        check_before_resetprop "ro.boot.vbmeta.digest" "$BOOT_HASH"
        check_before_resetprop "ro.boot.vbmeta.size" "$VBMETA_SIZE"
        check_before_resetprop "ro.boot.vbmeta.avb_version" "$AVB_VERSION"
    fi

}

encryption_disguiser(){

    [ -n "$CRYPTO_STATE" ] && check_before_resetprop "ro.crypto.state" "$CRYPTO_STATE"

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

    update_config_value "description" "$DESCRIPTION" "$MODULE_PROP"

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
module_status_update
debug_props_info
logowl "service.sh case closed!"

{

    MOD_REAL_TIME_DESC=""
    while true; do
        if [ "$UPDATE_REALTIME" = false ]; then
            print_line
            logowl "Detect flag UPDATE_REALTIME=false"
            logowl "Exit background task"
            exit 0
        fi

        if [ ! -f "$CONFIG_FILE" ]; then
            logowl "Configuration file $CONFIG_FILE does NOT exist!" "WARN"
            logowl "Exit background task"
            exit 1
        elif [ ! -f "$CONFIG_FILE_OLD" ]; then
            [ -f "$CONFIG_FILE" ] && cp "$CONFIG_FILE" "$CONFIG_FILE_OLD"
        elif ! file_compare "$CONFIG_FILE_OLD" "$CONFIG_FILE"; then
            logowl "Timestamp: $(date +"%Y-%m-%d %H:%M:%S")"
            logowl "Current update period: ${UPDATE_PERIOD}s"
            logowl "Detect changes in $CONFIG_FILE"
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
