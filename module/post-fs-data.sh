#!/system/bin/sh
MODDIR=${0%/*}

CONFIG_DIR="/data/adb/vbmetadisguiser"

CONFIG_FILE="$CONFIG_DIR/vbmeta.conf"
LOG_DIR="$CONFIG_DIR/logs"
LOG_FILE="$LOG_DIR/vd_sp_$(date +"%Y-%m-%d_%H-%M-%S").log"

MODULE_PROP="${MODDIR}/module.prop"
MOD_NAME="$(sed -n 's/^name=\(.*\)/\1/p' "$MODULE_PROP")"
MOD_AUTHOR="$(sed -n 's/^author=\(.*\)/\1/p' "$MODULE_PROP")"
MOD_VER="$(sed -n 's/^version=\(.*\)/\1/p' "$MODULE_PROP") ($(sed -n 's/^versionCode=\(.*\)/\1/p' "$MODULE_PROP"))"

TRICKY_STORE_CONFIG_FILE="/data/adb/tricky_store/security_patch.txt"
SECURITY_PATCH_DATE=""

debug_props_info() {

    print_line
    debug_get_prop ro.build.version.security_patch
    debug_get_prop ro.vendor.build.security_patch
    debug_get_prop ro.system.build.security_patch
    print_line

}

date_format_86() {

    key_name=$1
    key_date_value=$2

    [ -z "$key_name" ] || [ -z "$key_date_value" ] && return 1

    if echo "$key_date_value" | grep -qE '^[0-9]{8}$'; then
        formatted_date=$(echo "$key_date_value" | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1-\2-\3/')
        eval "$key_name=\"\$formatted_date\""
        logowl "Set $key_name=$formatted_date" "TIPS"

    elif echo "$key_date_value" | grep -qE '^[0-9]{6}$'; then
        formatted_date=$(echo "$key_date_value" | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)/\1-\2/')
        eval "$key_name=\"\$formatted_date\""
        logowl "Set $key_name=$formatted_date" "TIPS"
    elif echo "$key_date_value" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; then
        logowl "Current key $key_name=$key_date_value has been formatted already" "WARN"
    elif echo "$key_date_value" | grep -qE '^[0-9]{4}-[0-9]{2}$'; then
        logowl "Current key $key_name=$key_date_value has been formatted already" "WARN"
    else
        logowl "Invalid date format: $key_date_value" "ERROR"
        return 2
    fi
}

date_format_86() {
    key_name="$1"
    key_date_value="$2"

    [ -z "$key_name" ] || [ -z "$key_date_value" ] && return 1

    len=$(echo "$key_date_value" | awk '{print length}')
    format_success=false

    case "$len" in
        8)
            if echo "$key_date_value" | grep -qE '^[0-9]{8}$'; then
                formatted_date=$(echo "$key_date_value" | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1-\2-\3/')
                format_success=true
            fi
            ;;
        6)
            if echo "$key_date_value" | grep -qE '^[0-9]{6}$'; then
                formatted_date=$(echo "$key_date_value" | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)/\1-\2/')
                format_success=true
            fi
            ;;
        10)
            if echo "$key_date_value" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; then
                logowl "Current key $key_name=$key_date_value has been formatted already" "WARN"
                return 0
            fi
            ;;
        7)
            if echo "$key_date_value" | grep -qE '^[0-9]{4}-[0-9]{2}$'; then
                logowl "Current key $key_name=$key_date_value has been formatted already" "WARN"
                return 0
            fi
            ;;
        *)
            logowl "Invalid date format: $key_date_value" "ERROR"
            return 2
            ;;
    esac

    [ "$format_success" = false ] && { logowl "Invalid date format: $key_date_value" "ERROR"; return 2; }

    eval "$key_name=\"$formatted_date\""
    logowl "Set $key_name=$formatted_date" "TIPS"
}

ts_sp_config_simple() {
    logowl "Load security patch config (simple mode)"
    patch_level=$(grep -v '^#' "$TRICKY_STORE_CONFIG_FILE" | grep -Eo '[0-9]+' | head -n 1)

    if [ -z "$patch_level" ]; then
        logowl "Security patch level is NOT set yet!" "ERROR"
        exit 1
    fi

    verify_variables "patch_level" "$patch_level" "^[0-9]{8}$"
    date_format_86 "PATCH_LEVEL" "$PATCH_LEVEL"

    if [ -n "$PATCH_LEVEL" ]; then
        resetprop -n "ro.build.version.security_patch" "$PATCH_LEVEL"
        resetprop -n "ro.vendor.build.security_patch" "$PATCH_LEVEL"
        resetprop -n "ro.system.build.security_patch" "$PATCH_LEVEL"
    fi
}

ts_sp_config_advanced() {
    logowl "Load security patch config (advanced mode)"
    ts_all=$(init_variables "all" "$TRICKY_STORE_CONFIG_FILE")
    
    if [ -z "$ts_all" ]; then

        ts_system=$(init_variables "system" "$TRICKY_STORE_CONFIG_FILE")
        ts_boot=$(init_variables "boot" "$TRICKY_STORE_CONFIG_FILE")
        ts_vendor=$(init_variables "vendor" "$TRICKY_STORE_CONFIG_FILE")
        
        [ -n "$ts_system" ] && verify_variables "ts_system" "$ts_system" "^([0-9]{6}|[0-9]{8}|[0-9]{4}-[0-9]{2}-[0-9]{2})$"
        [ -n "$ts_boot" ] && verify_variables "ts_boot" "$ts_boot" "^([0-9]{6}|[0-9]{8}|[0-9]{4}-[0-9]{2}-[0-9]{2}|yes|no)$"
        [ -n "$ts_vendor" ] && verify_variables "ts_vendor" "$ts_vendor" "^([0-9]{6}|[0-9]{8}|[0-9]{4}-[0-9]{2}-[0-9]{2}|yes|no)$"
        
        [ -n "$TS_BOOT" ] && [ "$TS_BOOT" != "yes" ] && [ "$TS_BOOT" != "no" ] && date_format_86 "TS_BOOT" "$TS_BOOT"
        [ -n "$TS_VENDOR" ] && [ "$TS_VENDOR" != "yes" ] && [ "$TS_VENDOR" != "no" ] && date_format_86 "TS_VENDOR" "$TS_VENDOR"
    
    else

        [ -n "$ts_all" ] && verify_variables "ts_all" "$ts_all" "^([0-9]{6}|[0-9]{8}|[0-9]{4}-[0-9]{2}-[0-9]{2})$"
        [ -n "$TS_ALL" ] && date_format_86 "TS_ALL" "$TS_ALL"

    fi

    if [ -n "$TS_ALL" ]; then

        resetprop -n "ro.build.version.security_patch" "$TS_ALL"
        resetprop -n "ro.vendor.build.security_patch" "$TS_ALL"
        resetprop -n "ro.system.build.security_patch" "$TS_ALL"

    else

        [ -n "$TS_SYSTEM" ] && resetprop -n "ro.build.version.security_patch" "$TS_SYSTEM"

        if [ -n "$TS_BOOT" ]; then
            if [ "$TS_BOOT" = "yes" ]; then
                resetprop -n "ro.system.build.security_patch" "$TS_SYSTEM"
            elif [ "$TS_BOOT" = "no" ]; then
                logowl "boot=no, $MOD_NAME will NOT disguise boot partition security patch date" "WARN"
            else
                resetprop -n "ro.system.build.security_patch" "$TS_BOOT"
            fi
        fi

        if [ -n "$TS_VENDOR" ]; then
            if [ "$TS_VENDOR" = "yes" ]; then
                resetprop -n "ro.system.build.security_patch" "$TS_SYSTEM"
            elif [ "$TS_VENDOR" = "no" ]; then
                logowl "vendor=no, $MOD_NAME will NOT disguise vendor partition security patch date" "WARN"
            else
                resetprop -n "ro.vendor.build.security_patch" "$TS_VENDOR"
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
        logowl "Abnormal status! Both $TRICKY_STORE_CONFIG_FILE and $CONFIG_FILE are NULL!" "ERROR"
        return 1
    fi
}


. "$MODDIR/aautilities.sh"

init_logowl "$LOG_DIR"
module_intro >> "$LOG_FILE"
show_system_info
print_line
logowl "Start post-fs-data.sh"
print_line
logowl "Before:"
debug_props_info
security_patch_info_disguiser
print_line
logowl "After:"
debug_props_info
print_line
logowl "post-fs-data.sh case closed!"
