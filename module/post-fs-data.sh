#!/system/bin/sh
MODDIR=${0%/*}

. "$MODDIR/aa-util.sh"

CONFIG_DIR="/data/adb/vbmetadisguiser"
CONFIG_FILE="$CONFIG_DIR/vbmeta.conf"

LOG_DIR="$CONFIG_DIR/logs"
LOG_FILE="$LOG_DIR/vd_core_sp_$(date +"%Y%m%dT%H%M%S").log"
SLAIN_PROPS="$LOG_DIR/slain_props.prop"

TRICKY_STORE_CONFIG_FILE="/data/adb/tricky_store/security_patch.txt"

SECURITY_PATCH_DATE="2025-06-01"

AVB_VERSION="2.0"
VBMETA_SIZE="4096"
BOOT_HASH="00000000000000000000000000000000"

PROPS_SLAY=false
PROPS_LIST=""

config_loader() {

    logowl "Load config"

    avb_version=$(get_config_var "avb_version" "$CONFIG_FILE")
    vbmeta_size=$(get_config_var "vbmeta_size" "$CONFIG_FILE")
    boot_hash=$(get_config_var "boot_hash" "$CONFIG_FILE")
    props_slay=$(get_config_var "props_slay" "$CONFIG_FILE")
    props_list=$(get_config_var "props_list" "$CONFIG_FILE")

    verify_var "avb_version" "$avb_version" "^[1-9][0-9]*\.[0-9]*$|^[1-9][0-9]*$"
    verify_var "vbmeta_size" "$vbmeta_size" "^[1-9][0-9]*$"
    verify_var "boot_hash" "$boot_hash" "^[0-9a-fA-F]+$"
    verify_var "props_slay" "$props_slay" "^(true|false)$"
    verify_var "props_list" "$props_list" "^[a-zA-Z0-9/_\. @-]*$"

}

date_format_convert() {

    key_name="$1"
    key_date_value="$2"

    [ -z "$key_name" ] || [ -z "$key_date_value" ] && return 1

    len=$(echo "$key_date_value" | awk '{print length}')
    case "$len" in
        6)
            if echo "$key_date_value" | grep -qE '^[0-9]{6}$'; then
                formatted_date=$(echo "$key_date_value" | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)/\1-\2-01/')
            fi
            ;;
        7)
            if echo "$key_date_value" | grep -qE '^[0-9]{4}-[0-9]{2}$'; then
                formatted_date="${key_date_value}-01"
                return 0
            fi
            ;;
        8)
            if echo "$key_date_value" | grep -qE '^[0-9]{8}$'; then
                formatted_date=$(echo "$key_date_value" | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1-\2-\3/')
            fi
            ;;

        10)
            if echo "$key_date_value" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; then
                return 0
            fi
            ;;
        *)  return 1
            ;;
    esac

    eval "$key_name=\"$formatted_date\""
    logowl "Set $key_name=$formatted_date" "TIPS"

}

ts_sp_config_simple() {

    logowl "$TRICKY_STORE_CONFIG_FILE is set as simple mode"
    patch_level=$(grep -v '^#' "$TRICKY_STORE_CONFIG_FILE" | grep -Eo '[0-9]+' | head -n 1)

    [ -z "$patch_level" ] && return 1

    verify_var "patch_level" "$patch_level" "^[0-9]{8}$"
    date_format_convert "PATCH_LEVEL" "$PATCH_LEVEL"

    if [ -n "$PATCH_LEVEL" ]; then
        resetprop "ro.build.version.security_patch" "$PATCH_LEVEL"
        resetprop "ro.vendor.build.security_patch" "$PATCH_LEVEL"
        resetprop "ro.system.build.security_patch" "$PATCH_LEVEL"
    fi

}

ts_sp_config_advanced() {

    logowl "$TRICKY_STORE_CONFIG_FILE is set as advanced mode"
    ts_all=$(get_config_var "all" "$TRICKY_STORE_CONFIG_FILE")
    
    if [ -n "$ts_all" ]; then
        verify_var "ts_all" "$ts_all" "^([0-9]{6}|[0-9]{8}|[0-9]{4}-[0-9]{2}-[0-9]{2})$"
        date_format_convert "TS_ALL" "$TS_ALL"
    else
        ts_system=$(get_config_var "system" "$TRICKY_STORE_CONFIG_FILE")
        ts_boot=$(get_config_var "boot" "$TRICKY_STORE_CONFIG_FILE")
        ts_vendor=$(get_config_var "vendor" "$TRICKY_STORE_CONFIG_FILE")
        
        [ -z "$ts_system" ] && [ -z "$ts_boot" ] && [ -z "$ts_vendor" ] && return 1

        verify_var "ts_system" "$ts_system" "^([0-9]{6}|[0-9]{8}|[0-9]{4}-[0-9]{2}-[0-9]{2})$"
        verify_var "ts_boot" "$ts_boot" "^([0-9]{6}|[0-9]{8}|[0-9]{4}-[0-9]{2}-[0-9]{2}|yes|no)$"
        verify_var "ts_vendor" "$ts_vendor" "^([0-9]{6}|[0-9]{8}|[0-9]{4}-[0-9]{2}-[0-9]{2}|yes|no)$"
        
        [ -n "$TS_BOOT" ] && [ "$TS_BOOT" != "yes" ] && [ "$TS_BOOT" != "no" ] && date_format_convert "TS_BOOT" "$TS_BOOT"
        [ -n "$TS_VENDOR" ] && [ "$TS_VENDOR" != "yes" ] && [ "$TS_VENDOR" != "no" ] && date_format_convert "TS_VENDOR" "$TS_VENDOR"

    fi

    if [ -n "$TS_ALL" ]; then
        resetprop "ro.build.version.security_patch" "$TS_ALL"
        resetprop "ro.vendor.build.security_patch" "$TS_ALL"
        resetprop "ro.system.build.security_patch" "$TS_ALL"
    else
        [ -n "$TS_SYSTEM" ] && resetprop "ro.build.version.security_patch" "$TS_SYSTEM"
        if [ -n "$TS_BOOT" ]; then
            if [ "$TS_BOOT" = "yes" ]; then
                resetprop "ro.system.build.security_patch" "$TS_SYSTEM"
            elif [ "$TS_BOOT" = "no" ]; then
                logowl "boot=no, skip disguising" "WARN"
            else
                resetprop "ro.system.build.security_patch" "$TS_BOOT"
            fi
        fi
        if [ -n "$TS_VENDOR" ]; then
            if [ "$TS_VENDOR" = "yes" ]; then
                resetprop "ro.system.build.security_patch" "$TS_SYSTEM"
            elif [ "$TS_VENDOR" = "no" ]; then
                logowl "vendor=no, skip disguising" "WARN"
            else
                resetprop "ro.vendor.build.security_patch" "$TS_VENDOR"
            fi
        fi
    fi

}

security_patch_info_disguiser() {

    logowl "Disguise security patch properties"

    if [ -f "$TRICKY_STORE_CONFIG_FILE" ]; then
        TS_FILE_CONTENT=$(cat "$TRICKY_STORE_CONFIG_FILE")
        if printf '%s\n' "$TS_FILE_CONTENT" | grep -q '='; then
            ts_sp_config_advanced
        else
            ts_sp_config_simple
        fi
    elif [ ! -f "$TRICKY_STORE_CONFIG_FILE" ] && [ -f "$CONFIG_FILE" ]; then
        logowl "Tricky Store security patch config file" "WARN"
        logowl "$TRICKY_STORE_CONFIG_FILE does NOT exist"
        logowl "$MOD_NAME will try to fetch config from $CONFIG_FILE"    
        TRICKY_STORE_CONFIG_FILE="$CONFIG_FILE"
        ts_sp_config_advanced
    else
        logowl "Both Tricky Store config and" "WARN"
        logowl "VBMeta Disguiser config does NOT exist!"
    fi

}

vbmeta_disguiser() {

    logowl "Disguise VBMeta partition properties"

    resetprop "ro.boot.vbmeta.device_state" "locked"
    resetprop "ro.boot.vbmeta.hash_alg" "sha256"

    if [ -s "$CONFIG_FILE" ]; then
        resetprop "ro.boot.vbmeta.digest" "$BOOT_HASH"
        resetprop "ro.boot.vbmeta.size" "$VBMETA_SIZE"
        resetprop "ro.boot.vbmeta.avb_version" "$AVB_VERSION"
    fi

}

props_slayer() {
    
    [ -z "$PROPS_LIST" ] && [ -z "$PROPS_SLAY" ] && return 1

    if [ "$PROPS_SLAY" = false ]; then
        logowl "Properties Slayer is disabled"
        if [ -f "$SLAIN_PROPS" ]; then
            logowl "Restore slain properties"
            resetprop -p -f "$SLAIN_PROPS"
            logowl "Remove slain properties backup file"
            rm -f "$SLAIN_PROPS"
        fi
        return 0
    fi

    logowl "Remove specific properties"

    for props_r in $PROPS_LIST; do
        props_r_value="$(getprop $props_r)"
        [ -n "$props_r_value" ] && echo "${props_r}=$(getprop $props_r)" >> "$SLAIN_PROPS"
        check_and_slayprop $props_r
    done

    clean_duplicate_items "$SLAIN_PROPS"

}

soft_bootloader_spoof() {

    logowl "Reset specific bootloader properties"

    check_and_resetprop "ro.debuggable" "0"
    check_and_resetprop "ro.force.debuggable" "0"
    check_and_resetprop "ro.secure" "1"
    check_and_resetprop "ro.adb.secure" "1"

    check_and_resetprop "ro.boot.warranty_bit" "0"
    check_and_resetprop "ro.warranty_bit" "0"

    check_and_resetprop "ro.vendor.boot.warranty_bit" "0"
    check_and_resetprop "ro.vendor.warranty_bit" "0"
    check_and_resetprop "ro.boot.realmebootstate" "green"
    check_and_resetprop "ro.is_ever_orange" "0"

    for prop in $(resetprop | grep -oE 'ro.*.build.tags'); do
        check_and_resetprop "$prop" "release-keys"
    done
    for prop in $(resetprop | grep -oE 'ro.*.build.type'); do
        check_and_resetprop "$prop" "user"
    done
    check_and_resetprop "ro.build.type" "user"
    check_and_resetprop "ro.build.tags" "release-keys"

}

logowl_init "$LOG_DIR"
module_intro >> "$LOG_FILE"
show_system_info
print_line
logowl "Start post-fs-data.sh"
config_loader
print_line
vbmeta_disguiser
security_patch_info_disguiser
props_slayer
soft_bootloader_spoof
print_line
logowl "Check properties"
debug_props_info
print_line
logowl "post-fs-data.sh case closed!"
