#!/system/bin/sh
MODDIR=${0%/*}

CONFIG_DIR="/data/adb/vbmetadisguiser"

CONFIG_FILE="$CONFIG_DIR/vbmeta.conf"
LOG_DIR="$CONFIG_DIR/logs"
LOG_FILE="$LOG_DIR/vd_log_spatch_$(date +"%Y-%m-%d_%H-%M-%S").log"

MODULE_PROP="${MODDIR}/module.prop"
MOD_NAME="$(sed -n 's/^name=\(.*\)/\1/p' "$MODULE_PROP")"
MOD_AUTHOR="$(sed -n 's/^author=\(.*\)/\1/p' "$MODULE_PROP")"
MOD_VER="$(sed -n 's/^version=\(.*\)/\1/p' "$MODULE_PROP") ($(sed -n 's/^versionCode=\(.*\)/\1/p' "$MODULE_PROP"))"

TRICKY_STORE_CONFIG_FILE="/data/adb/tricky_store/security_patch.txt"
SECURITY_PATCH_DATE=""

debug_props_info() {

    print_line
    logowl " " "SPACE"
    logowl "ro.build.version.security_patch=$(getprop ro.build.version.security_patch)" "SPACE"
    logowl "ro.vendor.build.security_patch=$(getprop ro.vendor.build.security_patch)" "SPACE"
    logowl "ro.system.build.security_patch=$(getprop ro.system.build.security_patch)" "SPACE"
    logowl " " "SPACE"
    print_line

}

date_format_86() {

    key_name=$1
    key_date_value=$2

    if [ -z "$key_name" ] || [ -z "$key_date_value" ]; then
        logowl "Key name or date is NULL!" "ERROR"
        return 1
    fi

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

ts_sp_config_simple() {

    logowl "Loading config (simple mode)"

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

    logowl "Loading config (advanced mode)"

    ts_all=$(init_variables "all" "$TRICKY_STORE_CONFIG_FILE")
    ts_system=$(init_variables "system" "$TRICKY_STORE_CONFIG_FILE")
    ts_boot=$(init_variables "boot" "$TRICKY_STORE_CONFIG_FILE")
    ts_vendor=$(init_variables "vendor" "$TRICKY_STORE_CONFIG_FILE")

    if [ -n "$ts_all" ]; then
        verify_variables "ts_all" "$ts_all" "^([0-9]{6}|[0-9]{8}|[0-9]{4}-[0-9]{2}-[0-9]{2})$"
        date_format_86 "TS_ALL" "$TS_ALL"
    else
        verify_variables "ts_system" "$ts_system" "^([0-9]{6}|[0-9]{8}|[0-9]{4}-[0-9]{2}-[0-9]{2})$"
        date_format_86 "TS_SYSTEM" "$TS_SYSTEM"

        verify_variables "ts_boot" "$ts_boot" "^([0-9]{6}|[0-9]{8}|[0-9]{4}-[0-9]{2}-[0-9]{2}|yes|no)$"
        if [ "$TS_BOOT" != "yes" ] && [ "$TS_BOOT" != "no" ]; then
            date_format_86 "TS_BOOT" "$TS_BOOT"
        fi
        
        verify_variables "ts_vendor" "$ts_vendor" "^([0-9]{6}|[0-9]{8}|[0-9]{4}-[0-9]{2}-[0-9]{2}|yes|no)$"
        if [ "$TS_VENDOR" != "yes" ] && [ "$TS_VENDOR" != "no" ]; then
            date_format_86 "TS_VENDOR" "$TS_VENDOR"
        fi
    fi

    if [ -n "$TS_ALL" ]; then
        resetprop -n "ro.build.version.security_patch" "$TS_ALL"
        resetprop -n "ro.vendor.build.security_patch" "$TS_ALL"
        resetprop -n "ro.system.build.security_patch" "$TS_ALL"
    else
        if [ -n "$TS_SYSTEM" ]; then
            resetprop -n "ro.build.version.security_patch" "$TS_SYSTEM"
        fi

        if [ -n "$TS_BOOT" ] && [ "$TS_BOOT" = "yes" ]; then
            resetprop -n "ro.system.build.security_patch" "$TS_SYSTEM"
        elif [ -n "$TS_BOOT" ] && [ "$TS_BOOT" = "no" ]; then
            logowl "Detect boot=no, will NOT disguise boot partition security patch date" "WARN"
        elif [ -n "$TS_BOOT" ]; then
            resetprop -n "ro.system.build.security_patch" "$TS_BOOT"
        fi

        if [ -n "$TS_VENDOR" ] && [ "$TS_VENDOR" = "yes" ]; then
            resetprop -n "ro.system.build.security_patch" "$TS_SYSTEM"
        elif [ -n "$TS_VENDOR" ] && [ "$TS_VENDOR" = "no" ]; then
            logowl "Detect vendor=no, will NOT disguise vendor partition security patch date" "WARN"
        elif [ -n "$TS_VENDOR" ]; then
            resetprop -n "ro.vendor.build.security_patch" "$TS_VENDOR"
        fi
    fi

}

security_patch_info_disguiser() {

    logowl "Before:"
    debug_props_info
    
    if [ -f "$TRICKY_STORE_CONFIG_FILE" ]; then

        TS_FILE_CONTENT=$(cat "$TRICKY_STORE_CONFIG_FILE")

        if printf '%s\n' "$TS_FILE_CONTENT" | grep -q '='; then
            logowl "Detect $TRICKY_STORE_CONFIG_FILE is set as advanced mode" "TIPS"
            ts_sp_config_advanced
        else
            logowl "Detect $TRICKY_STORE_CONFIG_FILE is set as simple mode" "TIPS"
            ts_sp_config_simple
        fi
    else
        logowl "Tricky Store security patch config file ($TRICKY_STORE_CONFIG_FILE) does NOT exist!" "ERROR"
        logowl "$MOD_NAME will try to fetch config from $CONFIG_FILE"
    fi

    logowl "After:"
    debug_props_info
}

. "$MODDIR/aautilities.sh"

init_logowl "$LOG_DIR"
module_intro >> "$LOG_FILE"
show_system_info
print_line
logowl "Starting post-fs-data.sh"
print_line
security_patch_info_disguiser
print_line
logowl "post-fs-data.sh case closed!"
