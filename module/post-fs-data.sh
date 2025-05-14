#!/system/bin/sh
MODDIR=${0%/*}

CONFIG_DIR="/data/adb/vbmetadisguiser"

CONFIG_FILE="$CONFIG_DIR/vbmeta.conf"
LOG_DIR="$CONFIG_DIR/logs"
LOG_FILE="$LOG_DIR/vd_spcfg_$(date +"%Y-%m-%d_%H-%M-%S").log"

MODULE_PROP="${MODDIR}/module.prop"
MOD_NAME="$(sed -n 's/^name=\(.*\)/\1/p' "$MODULE_PROP")"
MOD_AUTHOR="$(sed -n 's/^author=\(.*\)/\1/p' "$MODULE_PROP")"
MOD_VER="$(sed -n 's/^version=\(.*\)/\1/p' "$MODULE_PROP") ($(sed -n 's/^versionCode=\(.*\)/\1/p' "$MODULE_PROP"))"

MN_SUPPORT=false
MR_SUPPORT=false

TRICKY_STORE_CONFIG_FILE="/data/adb/tricky_store/security_patch.txt"
SECURITY_PATCH_DATE=""

config_loader() {

    logowl "Load config"

    if [ "$DETECT_KSU" = true ] || [ "$DETECT_APATCH" = true ]; then
        logowl "$MOD_NAME is running on KernelSU / APatch"
        logowl "Make Node mode support is present"
        MN_SUPPORT=true
        MR_SUPPORT=false

    elif [ "$DETECT_MAGISK" = true ]; then
        logowl "$MOD_NAME is running on Magisk"
        logowl "Magisk Replace mode support is present"
        MR_SUPPORT=true
        if [ $MAGISK_V_VER_CODE -ge 28102 ]; then
            logowl "$MOD_NAME is running on Magisk 28102+"
            logowl "Make Node mode support is present"
            MN_SUPPORT=true
        else
            logowl "Make Node mode requires Magisk version 28102+!" "WARN"
            logowl "$MOD_NAME will revert to Magisk Replace mode"
            MN_SUPPORT=false
        fi
    fi

}

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

mirror_make_node() {

    node_path=$1

    if [ -z "$node_path" ]; then
        logowl "node_path is NOT ordered!" "ERROR"
        return 5
    elif [ ! -e "$node_path" ]; then
        logowl "$node_path does NOT exist!" "ERROR"
        return 6
    fi

    node_path_parent_dir=$(dirname "$node_path")
    mirror_parent_dir="$MODDIR$node_path_parent_dir"
    mirror_node_path="$MODDIR$node_path"

    if [ ! -d "$mirror_parent_dir" ]; then
        logowl "Parent dir $mirror_parent_dir does NOT exist"
        mkdir -p "$mirror_parent_dir"
        logowl "Create parent dir: $mirror_parent_dir"
    fi

    if [ ! -e "$mirror_node_path" ]; then
        logowl "Node $mirror_node_path does NOT exist"
        mknod "$mirror_node_path" c 0 0
        result_make_node="$?"
        logowl "Execute: mknod $mirror_node_path c 0 0"
        if [ $result_make_node -eq 0 ]; then
            return 0
        else
            return $result_make_node
        fi
    else
        logowl "Node $mirror_node_path exists already"
        return 0
    fi

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

custom_install_recovery_script_remove() {

    logowl "Start custom install-recovery.sh script removal process"

    block_install_recovery_script=$(init_variables "block_install_recovery_script" "$CONFIG_FILE")
    block_install_recovery_script_mode=$(init_variables "block_install_recovery_script_mode" "$CONFIG_FILE")
    custom_install_recovery_script_path=$(init_variables "custom_install_recovery_script_path" "$CONFIG_FILE")

    if [ -z "$custom_install_recovery_script_path" ]; then
        logowl "Custom install-recovery.sh path is NOT set" "ERROR"
        return 2
    fi

    WORK_MODE=""
    if [ "$block_install_recovery_script" = "false" ] || [ -z "$block_install_recovery_script" ]; then
        logowl "Custom install-recovery.sh removal feature is disabled"
        return 1
    elif [ "$block_install_recovery_script" = "true" ]; then

        if [ -z "$block_install_recovery_script_mode" ]; then
            logowl "Block install-recovery.sh mode is NOT set!" "ERROR"
            return 1
        fi

        if [ "$block_install_recovery_script_mode" = "MN" ]; then
            if [ "$MN_SUPPORT" = false ]; then
                logowl "Make Node mode needs Magisk version 28102 and higher, KernelSU or APatch!" "ERROR"
                logowl "However, either ED (Erase/Delete) or RN (Rename) mode is NOT systemless behavior"
                logowl "$MOD_NAME will skip these step directly and will NOT switch into ED or RN mode"
                logowl "Please adjust this option manually if need"
                return 2
            fi
        elif [ "$block_install_recovery_script_mode" = "RN" ] || [ "$block_install_recovery_script_mode" = "ED" ]; then
            if [ "$block_install_recovery_script_mode" = "RN" ]; then
                WORK_MODE="RN (Rename)"
            elif [ "$block_install_recovery_script_mode" = "ED" ]; then
                WORK_MODE="DE (Delete/Erase)"
            fi
            logowl "$WORK_MODE mode is NOT systemless behavior" "WARN"
            logowl "If your file system is read-only, it will NOT work at all...well it is okay"
            logowl "But if NOT, please make sure you know how to rescue from your device being brick!"
            logowl "Or make sure you have the method to modify the files located in /system partition by OrangeFox/TWRP"
            logowl "This option/method must be switched by yourself ONLY"
            logowl "You have been warned before you change the mode!" "WARN"
        else
            logowl "Abnormal block install-recovery.sh mode status!" "ERROR"
            return 1
        fi
    else
        logowl "Abnormal block install-recovery.sh switch status!" "ERROR"
        return 1
    fi

    IFS=' '
    SWITCH_TO_MN=false
    for ins_rec_sh in $custom_install_recovery_script_path; do
        if [ -f "$ins_rec_sh" ]; then
            if [ "$block_install_recovery_script_mode" = "RN" ]; then
                logowl "Rename $ins_rec_sh → ${ins_rec_sh}.old"
                if ! mv -n "$ins_rec_sh" "${ins_rec_sh}.old"; then
                    logowl "Rename failed (code: $?)" "ERROR";
                    [ "$MN_SUPPORT" = true ] && SWITCH_TO_MN=true
                else
                    continue
                fi
            elif [ "$block_install_recovery_script_mode" = "ED" ]; then
                logowl "Delete file: $ins_rec_sh"
                if ! rm -f "$ins_rec_sh"; then
                    logowl "Deletion failed (code: $?)" "ERROR";
                    [ "$MN_SUPPORT" = true ] && SWITCH_TO_MN=true
                else
                    continue
                fi
            fi

            if [ "$block_install_recovery_script_mode" = "MN" ] || [ "$SWITCH_TO_MN" = true ] ; then
                mirror_make_node "$ins_rec_sh" || { logowl "Failed to make node (code: $?)" "ERROR"; }
            fi

        else
            logowl "File not found: $ins_rec_sh" "WARN"
        fi
    done
    unset IFS
}

custom_addon_d_remove() {

    logowl "Start custom addon.d removal process"

    block_addon_d_dir=$(init_variables "block_addon_d_dir" "$CONFIG_FILE")
    block_addon_d_dir_mode=$(init_variables "block_addon_d_dir_mode" "$CONFIG_FILE")
    custom_addon_d_path=$(init_variables "custom_addon_d_path" "$CONFIG_FILE")

    if [ -z "$custom_addon_d_path" ]; then
        logowl "Custom addon.d path is NOT set" "ERROR"
        return 2
    fi

    WORK_MODE=""
    if [ "$block_addon_d_dir" = "false" ] || [ -z "$block_addon_d_dir" ]; then
        logowl "Custom addon.d removal feature is disabled"
        return 1
    elif [ "$block_addon_d_dir" = "true" ]; then
        
        if [ -z "$block_addon_d_dir_mode" ]; then
            logowl "Block addon.d mode is NOT set!" "ERROR"
            return 1
        fi

        if [ "$block_addon_d_dir_mode" = "MN" ]; then
            if [ "$MN_SUPPORT" = false ]; then
                logowl "Make Node mode needs Magisk version 28102 and higher, KernelSU or APatch!" "ERROR"
                logowl "However, either ED (Erase/Delete) or RN (Rename) mode is NOT systemless behavior"
                logowl "$MOD_NAME will skip these step directly and will NOT switch into ED or RN mode"
                logowl "Please adjust this option manually if need"
                return 2
            fi
        elif [ "$block_addon_d_dir_mode" = "RN" ] || [ "$block_addon_d_dir_mode" = "ED" ]; then
            if [ "$block_addon_d_dir_mode" = "RN" ]; then
                WORK_MODE="RN (Rename)"
            elif [ "$block_addon_d_dir_mode" = "ED" ]; then
                WORK_MODE="DE (Delete/Erase)"
            fi
            logowl "$WORK_MODE mode is NOT systemless behavior" "WARN"
            logowl "If your file system is read-only, it will NOT work at all...well it is okay"
            logowl "But if NOT, please make sure you know how to rescue from your device being brick!"
            logowl "Or make sure you have the method to modify the files located in /system partition by OrangeFox/TWRP"
            logowl "This option/method must be switched by yourself ONLY"
            logowl "You have been warned before you change the mode!" "WARN"
        else
            logowl "Abnormal block addon.d mode status!" "ERROR"
            return 1
        fi
    else
        logowl "Abnormal block addon.d switch status!" "ERROR"
        return 1
    fi

    IFS=' '
    SWITCH_TO_MN=false
    for addon_d in $custom_addon_d_path; do
        if [ -f "$addon_d" ]; then
            if [ "$block_addon_d_dir_mode" = "RN" ]; then
                logowl "Rename $addon_d → ${addon_d}.old"
                if ! mv -n "$addon_d" "${addon_d}.old"; then
                    logowl "Rename failed (code: $?)" "ERROR";
                    [ "$MN_SUPPORT" = true ] && SWITCH_TO_MN=true
                else
                    continue
                fi
            elif [ "$block_addon_d_dir_mode" = "ED" ]; then
                logowl "Delete file: $addon_d"
                if ! rm -f "$addon_d"; then
                    logowl "Deletion failed (code: $?)" "ERROR";
                    [ "$MN_SUPPORT" = true ] && SWITCH_TO_MN=true
                else
                    continue
                fi
            fi
            
            if [ "$block_addon_d_dir_mode" = "MN" ] || [ "$SWITCH_TO_MN" = true ]; then
                mirror_make_node "$addon_d" || { logowl "Failed to make node (code: $?)" "ERROR"; }
            fi

        else
            logowl "Dir not found: $addon_d" "WARN"
        fi
    done

}

. "$MODDIR/aautilities.sh"

init_logowl "$LOG_DIR"
module_intro >> "$LOG_FILE"
show_system_info
config_loader
print_line
logowl "Start post-fs-data.sh"
print_line
logowl "Before:"
debug_props_info
security_patch_info_disguiser
print_line
logowl "After:"
debug_props_info
custom_install_recovery_script_remove
custom_addon_d_remove
print_line
logowl "post-fs-data.sh case closed!"
