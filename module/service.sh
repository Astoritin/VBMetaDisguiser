#!/system/bin/sh
MODDIR=${0%/*}

CONFIG_DIR="/data/adb/vbmetadisguiser"

CONFIG_FILE="$CONFIG_DIR/vbmeta.conf"
LOG_DIR="$CONFIG_DIR/logs"
LOG_FILE="$LOG_DIR/vd_vbmetab_$(date +"%Y-%m-%d_%H-%M-%S").log"

CONFIG_FILE_OLD="$LOG_DIR/vbmeta_old.conf"

MODULE_PROP="${MODDIR}/module.prop"
MOD_NAME="$(sed -n 's/^name=\(.*\)/\1/p' "$MODULE_PROP")"
MOD_AUTHOR="$(sed -n 's/^author=\(.*\)/\1/p' "$MODULE_PROP")"
MOD_VER="$(sed -n 's/^version=\(.*\)/\1/p' "$MODULE_PROP") ($(sed -n 's/^versionCode=\(.*\)/\1/p' "$MODULE_PROP"))"
MOD_ROOT_DIR=$(dirname "$MODDIR")

MOD_INTRO="A Magisk module to disguise the props of vbmeta, security patch date and encryption status."

MOD_DESC_OLD="$(sed -n 's/^description=\(.*\)/\1/p' "$MODULE_PROP")"

TRICKY_STORE_CONFIG_FILE="/data/adb/tricky_store/security_patch.txt"
SHAMIKO_DIR="${MOD_ROOT_DIR}/zygisk_shamiko"
SENSITIVE_PROPS_DIR="${MOD_ROOT_DIR}/sensitive_props"

UPDATE_REALTIME=true
UPDATE_PERIOD=300

AVB_VERSION="2.0"
VBMETA_SIZE="4096"
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

debug_contains_and_reset_prop() {

    prop_name="$1"
    prop_contains_keyword="$2"
    prop_new_value="$3"

    [ -z "$prop_name" ] || [ -z "$prop_contains_keyword" ] || [ -z "$prop_new_value" ] && return 1
    
    prop_current_value=$(resetprop "$prop_name")

    if echo "$prop_current_value" | grep -q "$prop_contains_keyword"; then
        resetprop "$prop_name" "$prop_new_value"
        return 0
    fi

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

    logowl "Disguise VBMeta partition properties"

    resetprop -n "ro.boot.vbmeta.device_state" "locked"
    resetprop -n "ro.boot.vbmeta.hash_alg" "sha256"

    if [ -s "$CONFIG_FILE" ]; then
        resetprop -n "ro.boot.vbmeta.digest" "$BOOT_HASH"
        resetprop -n "ro.boot.vbmeta.size" "$VBMETA_SIZE"
        resetprop -n "ro.boot.vbmeta.avb_version" "$AVB_VERSION"
    fi

}

encryption_disguiser(){

    logowl "Disguise Data partition encryption property"

    [ -n "$CRYPTO_STATE" ] && resetprop -n "ro.crypto.state" "$CRYPTO_STATE"

}

module_status_update() {

    desc_max=3
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
        desc_vbmeta="✅VBMeta Hash: $vbmeta_digest ($vbmeta_hash_alg)"
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
        desc_ts_sp="✅Security patch: $security_patch"
        update_count=$((update_count + 1))
    fi

    desc_active=""
    if [ "$update_count" -eq "$desc_max" ]; then
        desc_active="✅All Done."
    elif [ "$update_count" -gt 0 ]; then
        desc_active="✅Done."
    else
        desc_active="❌No effect. Maybe something went wrong?"
    fi
    
    [ -n "$desc_active" ] && DESCRIPTION="[$desc_active $desc_vbmeta, $desc_avb, $desc_ts_sp, $desc_crypto, 📦Root: $ROOT_SOL_DETAIL] $MOD_INTRO"
    [ -n "$DESCRIPTION" ] && update_config_value "description" "$DESCRIPTION" "$MODULE_PROP"

}

soft_bootloader_spoof() {

    if [ -e "$SHAMIKO_DIR" ] || [ -e "$SENSITIVE_PROPS_DIR" ]; then
        return 0
    fi

    logowl "Reset specific bootloader properties"

    resetprop -n "ro.boot.vbmeta.device_state" "locked"
    resetprop -n "ro.boot.verifiedbootstate" "green"
    resetprop -n "ro.boot.flash.locked" "1"
    resetprop -n "ro.boot.veritymode" "enforcing"
    resetprop -n "ro.boot.warranty_bit" "0"
    resetprop -n "ro.warranty_bit" "0"
    resetprop -n "ro.debuggable" "0"
    resetprop -n "ro.force.debuggable" "0"
    resetprop -n "ro.secure" "1"
    resetprop -n "ro.adb.secure" "1"
    resetprop -n "ro.build.type" "user"
    resetprop -n "ro.build.tags" "release-keys"
    resetprop -n "ro.vendor.boot.warranty_bit" "0"
    resetprop -n "ro.vendor.warranty_bit" "0"
    resetprop -n "vendor.boot.vbmeta.device_state" "locked"
    resetprop -n "vendor.boot.verifiedbootstate" "green"

    resetprop -n "sys.oem_unlock_allowed" "0"
    resetprop -n "ro.oem_unlock_supported" "0"

    resetprop -n "ro.boot.realmebootstate" "green"
    resetprop -n "ro.boot.realme.lockstate" "1"

    resetprop -n "ro.secureboot.lockstate" "locked"

    resetprop -n "init.svc.flash_recovery" "stopped"

    debug_contains_and_reset_prop "ro.bootmode" "recovery" "unknown"
    debug_contains_and_reset_prop "ro.boot.bootmode" "recovery" "unknown"
    debug_contains_and_reset_prop "vendor.boot.bootmode" "recovery" "unknown"

}


. "$MODDIR/aautilities.sh"

init_logowl "$LOG_DIR"
module_intro >> "$LOG_FILE"
show_system_info
print_line
logowl "Start service.sh"
print_line
[ -f "$CONFIG_FILE" ] && cp "$CONFIG_FILE" "$CONFIG_FILE_OLD"
config_loader
vbmeta_disguiser
encryption_disguiser
soft_bootloader_spoof
module_status_update
print_line
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

        if [ -f "$CONFIG_FILE_OLD" ] && [ -f "$CONFIG_FILE" ]; then
            if ! file_compare "$CONFIG_FILE_OLD" "$CONFIG_FILE"; then
                logowl "Detect changes in file $CONFIG_FILE"
                logowl "Current timestamp: $(date +"%Y-%m-%d_%H-%M-%S")"
                config_loader
                vbmeta_disguiser
                encryption_disguiser
                module_status_update
                cp "$CONFIG_FILE" "$CONFIG_FILE_OLD"
            fi
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
        elif [ "$MOD_CURRENT_STATUS" = "remove" ]; then
            MOD_REAL_TIME_DESC="[🗑️Reboot to remove. 📦Root: $ROOT_SOL_DETAIL] $MOD_INTRO"
            update_config_value "description" "$MOD_REAL_TIME_DESC" "$MODULE_PROP"
        elif [ "$MOD_CURRENT_STATUS" = "disable" ]; then
            MOD_REAL_TIME_DESC="[❌OFF or reboot to turn off. 📦Root: $ROOT_SOL_DETAIL] $MOD_INTRO"
            update_config_value "description" "$MOD_REAL_TIME_DESC" "$MODULE_PROP"
        elif [ "$MOD_CURRENT_STATUS" = "enable" ]; then
            module_status_update
        fi
        sleep "$UPDATE_PERIOD"
    done

} &