#!/system/bin/sh
MODDIR=${0%/*}

CONFIG_DIR="/data/adb/vbmetadisguiser"

CONFIG_FILE="$CONFIG_DIR/vbmeta.conf"
LOG_DIR="$CONFIG_DIR/logs"
LOG_FILE="$LOG_DIR/vd_core_a_$(date +"%Y-%m-%d_%H-%M-%S").log"

MODULE_PROP="${MODDIR}/module.prop"
MOD_NAME="$(sed -n 's/^name=\(.*\)/\1/p' "$MODULE_PROP")"
MOD_AUTHOR="$(sed -n 's/^author=\(.*\)/\1/p' "$MODULE_PROP")"
MOD_VER="$(sed -n 's/^version=\(.*\)/\1/p' "$MODULE_PROP") ($(sed -n 's/^versionCode=\(.*\)/\1/p' "$MODULE_PROP"))"

TRICKY_STORE_CONFIG_FILE="/data/adb/tricky_store/security_patch.txt"
SECURITY_PATCH_DATE=""

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
    
    avb_version=$(init_variables "avb_version" "$CONFIG_FILE")
    vbmeta_size=$(init_variables "vbmeta_size" "$CONFIG_FILE")
    boot_hash=$(init_variables "boot_hash" "$CONFIG_FILE")

    verify_variables "avb_version" "$avb_version" "^[1-9][0-9]*\.[0-9]*$|^[1-9][0-9]*$"
    verify_variables "vbmeta_size" "$vbmeta_size" "^[1-9][0-9]*$"
    verify_variables "boot_hash" "$boot_hash" "^[0-9a-fA-F]+$"

}

date_format_86() {

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

        *)
            logowl "Invalid date format: $key_date_value" "ERROR"
            return 2
            ;;
    esac

    eval "$key_name=\"$formatted_date\""
    logowl "Set $key_name=$formatted_date" "TIPS"

}

ts_sp_config_simple() {

    logowl "Load security patch config (simple mode)"
    patch_level=$(grep -v '^#' "$TRICKY_STORE_CONFIG_FILE" | grep -Eo '[0-9]+' | head -n 1)

    if [ -z "$patch_level" ]; then
        logowl "Security patch level is NOT set yet!" "ERROR"
        return 1
    fi

    verify_var "patch_level" "$patch_level" "^[0-9]{8}$"
    date_format_86 "PATCH_LEVEL" "$PATCH_LEVEL"

    if [ -n "$PATCH_LEVEL" ]; then
        check_before_resetprop "ro.build.version.security_patch" "$PATCH_LEVEL"
        check_before_resetprop "ro.vendor.build.security_patch" "$PATCH_LEVEL"
        check_before_resetprop "ro.system.build.security_patch" "$PATCH_LEVEL"
    fi

}

ts_sp_config_advanced() {

    logowl "Load security patch config (advanced mode)"
    ts_all=$(get_config_var "all" "$TRICKY_STORE_CONFIG_FILE")
    
    if [ -n "$ts_all" ]; then
        verify_var "ts_all" "$ts_all" "^([0-9]{6}|[0-9]{8}|[0-9]{4}-[0-9]{2}-[0-9]{2})$"
        date_format_86 "TS_ALL" "$TS_ALL"
    else
        ts_system=$(get_config_var "system" "$TRICKY_STORE_CONFIG_FILE")
        ts_boot=$(get_config_var "boot" "$TRICKY_STORE_CONFIG_FILE")
        ts_vendor=$(get_config_var "vendor" "$TRICKY_STORE_CONFIG_FILE")
        
        [ -n "$ts_system" ] && verify_var "ts_system" "$ts_system" "^([0-9]{6}|[0-9]{8}|[0-9]{4}-[0-9]{2}-[0-9]{2})$"
        [ -n "$ts_boot" ] && verify_var "ts_boot" "$ts_boot" "^([0-9]{6}|[0-9]{8}|[0-9]{4}-[0-9]{2}-[0-9]{2}|yes|no)$"
        [ -n "$ts_vendor" ] && verify_var "ts_vendor" "$ts_vendor" "^([0-9]{6}|[0-9]{8}|[0-9]{4}-[0-9]{2}-[0-9]{2}|yes|no)$"
        
        [ -n "$TS_BOOT" ] && [ "$TS_BOOT" != "yes" ] && [ "$TS_BOOT" != "no" ] && date_format_86 "TS_BOOT" "$TS_BOOT"
        [ -n "$TS_VENDOR" ] && [ "$TS_VENDOR" != "yes" ] && [ "$TS_VENDOR" != "no" ] && date_format_86 "TS_VENDOR" "$TS_VENDOR"
    fi

    if [ -n "$TS_ALL" ]; then

        check_before_resetprop "ro.build.version.security_patch" "$TS_ALL"
        check_before_resetprop "ro.vendor.build.security_patch" "$TS_ALL"
        check_before_resetprop "ro.system.build.security_patch" "$TS_ALL"

    else

        [ -n "$TS_SYSTEM" ] && check_before_resetprop "ro.build.version.security_patch" "$TS_SYSTEM"

        if [ -n "$TS_BOOT" ]; then
            if [ "$TS_BOOT" = "yes" ]; then
                check_before_resetprop "ro.system.build.security_patch" "$TS_SYSTEM"
            elif [ "$TS_BOOT" = "no" ]; then
                logowl "boot=no, $MOD_NAME will NOT disguise boot partition security patch date" "WARN"
            else
                check_before_resetprop "ro.system.build.security_patch" "$TS_BOOT"
            fi
        fi

        if [ -n "$TS_VENDOR" ]; then
            if [ "$TS_VENDOR" = "yes" ]; then
                check_before_resetprop "ro.system.build.security_patch" "$TS_SYSTEM"
            elif [ "$TS_VENDOR" = "no" ]; then
                logowl "vendor=no, $MOD_NAME will NOT disguise vendor partition security patch date" "WARN"
            else
                check_before_resetprop "ro.vendor.build.security_patch" "$TS_VENDOR"
            fi
        fi
    fi

}

security_patch_info_disguiser() {

    if [ -f "$TRICKY_STORE_CONFIG_FILE" ]; then
        TS_FILE_CONTENT=$(cat "$TRICKY_STORE_CONFIG_FILE")

        if printf '%s\n' "$TS_FILE_CONTENT" | grep -q '='; then
            logowl "Detect $TRICKY_STORE_CONFIG_FILE is set as advanced mode" "TIPS"
            ts_sp_config_advanced
        else
            logowl "Detect $TRICKY_STORE_CONFIG_FILE is set as simple mode" "TIPS"
            ts_sp_config_simple
        fi

    elif [ ! -f "$TRICKY_STORE_CONFIG_FILE" ] && [ -f "$CONFIG_FILE" ]; then
        logowl "Tricky Store security patch config file ($TRICKY_STORE_CONFIG_FILE) does NOT exist!" "WARN"
        logowl "$MOD_NAME will try to fetch config from $CONFIG_FILE"
    
        TRICKY_STORE_CONFIG_FILE="$CONFIG_FILE"
        ts_sp_config_advanced

    else
        logowl "Both Tricky Store config and VBMeta Disguiser config does NOT exist!" "ERROR"
        return 1
    fi

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

. "$MODDIR/aa-util.sh"

logowl_init "$LOG_DIR"
module_intro >> "$LOG_FILE"
show_system_info
print_line
logowl "Start post-fs-data.sh"
print_line
logowl "Before:"
debug_props_info
config_loader
security_patch_info_disguiser && logowl "Disguise security patch properties"
vbmeta_disguiser && logowl "Disguise VBMeta partition properties"
print_line
logowl "After:"
debug_props_info
print_line
logowl "post-fs-data.sh case closed!"
