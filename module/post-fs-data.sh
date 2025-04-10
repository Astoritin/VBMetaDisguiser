#!/system/bin/sh
MODDIR=${0%/*}

CONFIG_DIR="/data/adb/vbmetadisguiser"

CONFIG_FILE="$CONFIG_DIR/vbmeta.conf"
LOG_DIR="$CONFIG_DIR/logs"
LOG_FILE="$LOG_DIR/vd_log_core_a_$(date +"%Y-%m-%d_%H-%M-%S").log"

MODULE_PROP="${MODDIR}/module.prop"
MOD_NAME="$(sed -n 's/^name=\(.*\)/\1/p' "$MODULE_PROP")"
MOD_AUTHOR="$(sed -n 's/^author=\(.*\)/\1/p' "$MODULE_PROP")"
MOD_VER="$(sed -n 's/^version=\(.*\)/\1/p' "$MODULE_PROP") ($(sed -n 's/^versionCode=\(.*\)/\1/p' "$MODULE_PROP"))"

TRICKY_STORE_CONFIG_FILE="/data/adb/tricky_store/security_patch.txt"
SECURITY_PATCH_DATE=""

debug_props_info() {

    logowl " " "SPACE"
    logowl "ro.build.version.security_patch=$(getprop ro.build.version.security_patch)" "SPACE"
    logowl "ro.vendor.build.security_patch=$(getprop ro.vendor.build.security_patch)" "SPACE"
    logowl "ro.system.build.security_patch=$(getprop ro.system.build.security_patch)" "SPACE"
    logowl " " "SPACE"

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
    elif [ ! -f "$TRICKY_STORE_CONFIG_FILE" ] && [ -f "$CONFIG_FILE" ]; then
        logowl "Tricky Store security patch config file ($TRICKY_STORE_CONFIG_FILE) does NOT exist!" "ERROR"
        logowl "$MOD_NAME will try to fetch config from $CONFIG_FILE"
        TRICKY_STORE_CONFIG_FILE="$CONFIG_FILE"
        ts_sp_config_advanced
    else
        logowl "Abnormal status! Both $TRICKY_STORE_CONFIG_FILE and $CONFIG_FILE are NULL!" "ERROR"
        return 1
    fi

    logowl "After:"
    debug_props_info
}

custom_install_recovery_script_remove() {

    logowl "Starting custom install-recovery.sh script removal process"

    block_install_recovery_script=$(init_variables "block_install_recovery_script" "$CONFIG_FILE")
    block_install_recovery_script_mode=$(init_variables "block_install_recovery_script_mode" "$CONFIG_FILE")
    custom_install_recovery_script_path=$(init_variables "custom_install_recovery_script_path" "$CONFIG_FILE")

    if [ -z "$custom_install_recovery_script_path" ]; then
        logowl "Custom install-recovery.sh path is NOT set" "ERROR"
        return 2
    fi

    if [ "$block_install_recovery_script" = "false" ] || [ -z "$block_install_recovery_script" ]; then
        logowl "Custom install-recovery.sh removal feature is disabled"
        return 1
    elif [ "$block_install_recovery_script" = "true" ]; then
        if [ -z "$block_install_recovery_script_mode" ]; then
            logowl "Block install-recovery.sh mode is NOT set!" "ERROR"
            return 1
        elif [ "$block_install_recovery_script_mode" = "MN" ]; then
            if [ -n "$KSU" ] || [ -n "$APATCH" ]; then
                logowl "Current Mode: MN (Make Node)"
                logowl "Detect $MOD_NAME running on KernelSU / APatch, which supports Make Node mode"
            elif [ -n "$MAGISK_V_VER_CODE" ]; then
                if [ $MAGISK_V_VER_CODE -ge 28102 ]; then
                    logowl "Detect $MOD_NAME running on Magisk 28102+, which supports Make Node mode"
                fi
            else
                logowl "Make Node mode needs Magisk version 28102 and higher, KernelSU or APatch!" "ERROR"
                logowl "However, ED (Erase/Delete) mode is NOT systemless behavior"
                logowl "$MOD_NAME will skip these step directly and will NOT switch into ED mode"
                logowl "Please set block_install_recovery_script_mode=ED manually if need"
                return 2
            fi
        elif [ "$block_install_recovery_script_mode" = "RN" ]; then
            logowl "Current Mode: RN (Rename)"
            logowl "RN (Rename) mode is NOT systemless behavior" "WARN"
            logowl "If your file system is read-only, it will NOT work at all...well it is okay"
            logowl "But if NOT, please make sure you know how to rescue from your device being brick!"
            logowl "Or make sure you have the method to modify the files located in /system partition by OrangeFox/TWRP"
            logowl "This option/method must be switched by yourself ONLY, you have been warned before you change the mode"
        elif [ "$block_install_recovery_script_mode" = "ED" ]; then
            logowl "Current Mode: DE (Delete/Erase)"
            logowl "ED (Erase/Delete) mode is NOT systemless behavior" "WARN"
            logowl "If your file system is read-only, it will NOT work at all...well it is okay"
            logowl "But if NOT, please make sure you know how to rescue from your device being brick!"
            logowl "This option/method must be switched by yourself ONLY, you have been warned before you change the mode"
        else
            logowl "Abnormal block install-recovery.sh mode status!" "ERROR"
            return 1
        fi
    else
        logowl "Abnormal block install-recovery.sh switch status!" "ERROR"
        return 1
    fi

    IFS=' '
    for ins_rec_sh in $custom_install_recovery_script_path; do
        if [ -f "$ins_rec_sh" ]; then
            ins_parent_dir=$(dirname "$ins_rec_sh")
            mirror_ins_path="${MODDIR}${ins_parent_dir}"
            mirror_ins_file="${MODDIR}${ins_rec_sh}"

            if [ "$block_install_recovery_script_mode" = "MN" ]; then
                logowl "Create dir: $mirror_ins_path"
                mkdir -p "$mirror_ins_path"
                logowl "Create device node: $mirror_ins_file"
                mknod "$mirror_ins_file" c 0 0 || { logowl "Failed to create node (code: $?)" "ERROR"; }
            elif [ "$block_install_recovery_script_mode" = "RN" ]; then
                logowl "Rename $ins_rec_sh → ${ins_rec_sh}.old"
                mv -n "$ins_rec_sh" "${ins_rec_sh}.old" || { logowl "Rename failed (code: $?)" "ERROR"; }
            elif [ "$block_install_recovery_script_mode" = "ED" ]; then
                logowl "Delete file: $ins_rec_sh"
                rm -f "$ins_rec_sh" || { logowl "Deletion failed (code: $?)" "ERROR"; }
            fi
            logowl "Succeeded (code: $?)"
        else
            logowl "File not found: $ins_rec_sh" "WARN"
        fi
    done
    unset IFS

}

custom_addon_d_remove() {

    logowl "Starting custom addon.d removal process"

    block_addon_d_dir=$(init_variables "block_addon_d_dir" "$CONFIG_FILE")
    block_addon_d_dir_mode=$(init_variables "block_addon_d_dir_mode" "$CONFIG_FILE")
    custom_addon_d_path=$(init_variables "custom_addon_d_path" "$CONFIG_FILE")

    if [ -z "$custom_addon_d_path" ]; then
        logowl "Custom addon.d path is NOT set" "ERROR"
        return 2
    fi

    if [ "$block_addon_d_dir" = "false" ] || [ -z "$block_addon_d_dir" ]; then
        logowl "Custom addon.d removal feature is disabled"
        return 1
    elif [ "$block_addon_d_dir" = "true" ]; then
        if [ -z "$block_addon_d_dir_mode" ]; then
            logowl "Block addon.d mode is NOT set!" "ERROR"
            return 1
        elif [ "$block_addon_d_dir_mode" = "MN" ]; then
            if [ -n "$KSU" ] || [ -n "$APATCH" ]; then
                logowl "Current Mode: MN (Make Node)"
                logowl "Detect $MOD_NAME running on KernelSU / APatch, which supports Make Node mode"
            elif [ -n "$MAGISK_V_VER_CODE" ]; then
                if [ $MAGISK_V_VER_CODE -ge 28102 ]; then
                    logowl "Detect $MOD_NAME running on Magisk 28102+, which supports Make Node mode"
                fi
            else
                logowl "Make Node mode needs Magisk version 28102 and higher, KernelSU or APatch!" "ERROR"
                logowl "However, ED (Erase/Delete) mode is NOT systemless behavior"
                logowl "$MOD_NAME will skip these step directly and will NOT switch into ED mode"
                logowl "Please set block_addon_d_dir_mode=ED manually if need"
                return 2
            fi
        elif [ "$block_addon_d_dir_mode" = "RN" ]; then
            logowl "Current Mode: RN (Rename)"
            logowl "RN (Rename) mode is NOT systemless behavior" "WARN"
            logowl "If your file system is read-only, it will NOT work at all...well it is okay"
            logowl "But if NOT, please make sure you know how to rescue from your device being brick!"
            logowl "Or make sure you have the method to modify the files located in /system partition by OrangeFox/TWRP"
            logowl "This option/method must be switched by yourself ONLY, you have been warned before you change the mode"
        elif [ "$block_addon_d_dir_mode" = "ED" ]; then
            logowl "Current Mode: DE (Delete/Erase)"
            logowl "ED (Erase/Delete) mode is NOT systemless behavior" "WARN"
            logowl "If your file system is read-only, it will NOT work at all...well it is okay"
            logowl "But if NOT, please make sure you know how to rescue from your device being brick!"
            logowl "This option/method must be switched by yourself ONLY, you have been warned before you change the mode"
        else
            logowl "Abnormal block addon.d mode status!" "ERROR"
            return 1
        fi
    else
        logowl "Abnormal block addon.d switch status!" "ERROR"
        return 1
    fi

    IFS=' '
    for addon_d in $custom_addon_d_path; do
        if [ -f "$addon_d" ]; then
            addon_d_parent_dir=$(dirname "$addon_d")
            mirror_addon_d_path="${MODDIR}${addon_d_parent_dir}"
            mirror_addon_d_file="${MODDIR}${addon_d}"

            if [ "$block_addon_d_dir_mode" = "MN" ]; then
                logowl "Create dir: $mirror_addon_d_path"
                mkdir -p "$mirror_addon_d_path"
                logowl "Create device node: $mirror_addon_d_file"
                mknod "$mirror_addon_d_file" c 0 0 || { logowl "Failed to create node (code: $?)" "ERROR"; }
            elif [ "$block_addon_d_dir_mode" = "RN" ]; then
                logowl "Rename $addon_d → ${addon_d}.old"
                mv -n "$addon_d" "${addon_d}.old" || { logowl "Rename failed (code: $?)" "ERROR"; }
            elif [ "$block_addon_d_dir_mode" = "ED" ]; then
                logowl "Delete file: $addon_d"
                rm -f "$addon_d" || { logowl "Deletion failed (code: $?)" "ERROR"; }
            fi
            logowl "Succeeded (code: $?)"
        else
            logowl "Folder not found: $addon_d" "WARN"
        fi
    done
    unset IFS

}

. "$MODDIR/aautilities.sh"

init_logowl "$LOG_DIR"
module_intro >> "$LOG_FILE"
show_system_info
print_line
logowl "Starting post-fs-data.sh"
print_line
security_patch_info_disguiser
custom_install_recovery_script_remove
custom_addon_d_remove
print_line
logowl "post-fs-data.sh case closed!"
