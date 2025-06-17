#!/system/bin/sh
MODDIR=${0%/*}

. "$MODDIR/aa-util.sh"

CONFIG_DIR="/data/adb/vbmetadisguiser"
CONFIG_FILE="$CONFIG_DIR/vbmeta.conf"

LOG_DIR="$CONFIG_DIR/logs"
LOG_FILE="$LOG_DIR/vd_core_sp_$(date +"%Y%m%dT%H%M%S").log"

TRICKY_STORE_CONFIG_FILE="/data/adb/tricky_store/security_patch.txt"

addon_d_slay=false
install_recovery_slay=false

check_props() {

    logowl "Security patch date properties" ">"
    see_prop "ro.build.version.security_patch"
    see_prop "ro.system.build.security_patch"
    see_prop "ro.vendor.build.security_patch"

}

date_format_convert() {

    key_name="$1"
    key_date_value="$2"

    [ -z "$key_name" ] && return 1
    [ -z "$key_date_value" ] && return 1

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
    logowl "Set $key_name=$formatted_date" ">"

}

ts_sp_config_simple() {

    logowl "$TRICKY_STORE_CONFIG_FILE is set as simple mode"
    patch_level=$(grep -v '^#' "$TRICKY_STORE_CONFIG_FILE" | grep -Eo '[0-9]+' | head -n 1)

    [ -z "$patch_level" ] && return 1

    date_format_convert "patch_level" "$patch_level"

    if [ -n "$patch_level" ]; then
        check_and_resetprop "ro.build.version.security_patch" "$patch_level"
        check_and_resetprop "ro.vendor.build.security_patch" "$patch_level"
        check_and_resetprop "ro.system.build.security_patch" "$patch_level"
        return 0
    fi

}

ts_sp_config_advanced() {

    logowl "$TRICKY_STORE_CONFIG_FILE is set as advanced mode"
    ts_all=$(get_config_var "all" "$TRICKY_STORE_CONFIG_FILE")
    
    if [ -n "$ts_all" ]; then
        date_format_convert "ts_all" "$ts_all"
        check_and_resetprop "ro.build.version.security_patch" "$ts_all"
        check_and_resetprop "ro.vendor.build.security_patch" "$ts_all"
        check_and_resetprop "ro.system.build.security_patch" "$ts_all"
        return 0
    fi

    ts_system=$(get_config_var "system" "$TRICKY_STORE_CONFIG_FILE")
    ts_boot=$(get_config_var "boot" "$TRICKY_STORE_CONFIG_FILE")
    ts_vendor=$(get_config_var "vendor" "$TRICKY_STORE_CONFIG_FILE")
        
    [ -z "$ts_system" ] && [ -z "$ts_boot" ] && [ -z "$ts_vendor" ] && return 1

    if [ -n "$ts_system" ]; then
        check_and_resetprop "ro.build.version.security_patch" "$ts_system"
    fi

    if [ -n "$ts_boot" ]; then
        if [ "$ts_boot" = "yes" ]; then
            check_and_resetprop "ro.system.build.security_patch" "$ts_system"
        elif [ "$ts_boot" = "no" ]; then
            logowl "boot=no, skip disguising"
        else
            date_format_convert "ts_boot" "$ts_boot"
            check_and_resetprop "ro.system.build.security_patch" "$ts_boot"
        fi
    fi

    if [ -n "$ts_vendor" ]; then
        if [ "$ts_vendor" = "yes" ]; then
            check_and_resetprop "ro.system.build.security_patch" "$ts_system"
        elif [ "$ts_vendor" = "no" ]; then
            logowl "vendor=no, skip disguising"
        else
            date_format_convert "ts_vendor" "$ts_vendor"
            check_and_resetprop "ro.vendor.build.security_patch" "$ts_vendor"
        fi
    fi

    return 0

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

mirror_make_node() {

    node_path=$1

    if [ -z "$node_path" ]; then
        logowl "Node path is NOT ordered (5)" "ERROR"
        return 5
    elif [ ! -e "$node_path" ]; then
        logowl "$node_path does NOT exist (6)" "ERROR"
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
        logowl "mknod $mirror_node_path c 0 0 ($result_make_node)"
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

check_make_node_support() {
    
    logowl "$MOD_NAME is running on $ROOT_SOL"
    if [ "$DETECT_KSU" = true ] || [ "$DETECT_APATCH" = true ]; then
        logowl "Make Node support is present"
        MN_SUPPORT=true
    elif [ "$DETECT_MAGISK" = true ]; then
        if [ $MAGISK_V_VER_CODE -ge 28102 ]; then
            logowl "Make Node support is present"
            MN_SUPPORT=true
        else
            logowl "Make Node support is NOT present" "WARN"
            MN_SUPPORT=false
        fi
    fi

}

addon_d_slayer() {

    addon_d_path="/system/addon.d"

    addon_d_slay=$(get_config_var "addon_d_slay" "$CONFIG_FILE")
    [ -z "$addon_d_slay" ] && return 1

    if [ "$addon_d_slay" = false ]; then
        logowl "Flag addon_d_slay=false"
        return 0
    elif [ "$addon_d_slay" = true ]; then
        if [ "$MN_SUPPORT" = true ]; then
            logowl "Slay addon.d"
            mirror_make_node "$addon_d_path"
        else
            logowl "Flag MN_SUPPORT=false"
            logowl "Skip addon.d slayer"
        fi
    fi

}

install_recovery_script_slayer() {

    install_recovery_script_path="/system/bin/install-recovery.sh
/system/etc/install-recovery.sh
/system/etc/recovery-resource.dat
/system/recovery-from-boot.p
/system/vendor/bin/install-recovery.sh
/system/vendor/etc/install-recovery.sh
/system/vendor/recovery-from-boot.p
/system/vendor/etc/recovery-resource.dat"

    install_recovery_slay=$(get_config_var "install_recovery_slay" "$CONFIG_FILE")
    [ -z "$install_recovery_slay" ] && return 1

    if [ "$install_recovery_slay" = false ]; then
        logowl "Flag install_recovery_slay=false"
        return 0
    elif [ "$install_recovery_slay" = true ]; then
        if [ "$MN_SUPPORT" = true ]; then
            logowl "Slay install-recovery.sh"
            for irsh in $install_recovery_script_path; do
                if [ -f "$irsh" ]; then
                    logowl "Process: $irsh"
                    mirror_make_node "$irsh"
                fi
            done
        else
            logowl "Flag MN_SUPPORT=false"
            logowl "Skip install-recovery.sh slayer"
        fi
    fi

}

logowl_init "$LOG_DIR"
module_intro >> "$LOG_FILE"
show_system_info
print_line
logowl "Start post-fs-data.sh"
[ -n "$MODDIR" ] && rm -rf "$MODDIR/system"
print_line
logowl "Properties before disguise"
check_props
security_patch_info_disguiser
check_make_node_support
addon_d_slayer
install_recovery_script_slayer
print_line
set_permission_recursive "$MODDIR" 0 0 0755 0644
set_permission_recursive "$CONFIG_DIR" 0 0 0755 0644
logowl "Properties after disguise"
check_props
print_line
logowl "post-fs-data.sh case closed!"
#!/system/bin/sh
MODDIR=${0%/*}

. "$MODDIR/aa-util.sh"

CONFIG_DIR="/data/adb/vbmetadisguiser"
CONFIG_FILE="$CONFIG_DIR/vbmeta.conf"

LOG_DIR="$CONFIG_DIR/logs"
LOG_FILE="$LOG_DIR/vd_core_sp_$(date +"%Y%m%dT%H%M%S").log"

TRICKY_STORE_CONFIG_FILE="/data/adb/tricky_store/security_patch.txt"

addon_d_slay=false
install_recovery_slay=false

check_props() {

    logowl "Security patch date properties" ">"
    see_prop "ro.build.version.security_patch"
    see_prop "ro.system.build.security_patch"
    see_prop "ro.vendor.build.security_patch"

}

date_format_convert() {

    key_name="$1"
    key_date_value="$2"

    [ -z "$key_name" ] && return 1
    [ -z "$key_date_value" ] && return 1

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
    logowl "Set $key_name=$formatted_date" ">"

}

ts_sp_config_simple() {

    logowl "$TRICKY_STORE_CONFIG_FILE is set as simple mode"
    patch_level=$(grep -v '^#' "$TRICKY_STORE_CONFIG_FILE" | grep -Eo '[0-9]+' | head -n 1)

    [ -z "$patch_level" ] && return 1

    date_format_convert "patch_level" "$patch_level"

    if [ -n "$patch_level" ]; then
        check_and_resetprop "ro.build.version.security_patch" "$patch_level"
        check_and_resetprop "ro.vendor.build.security_patch" "$patch_level"
        check_and_resetprop "ro.system.build.security_patch" "$patch_level"
        return 0
    fi

}

ts_sp_config_advanced() {

    logowl "$TRICKY_STORE_CONFIG_FILE is set as advanced mode"
    ts_all=$(get_config_var "all" "$TRICKY_STORE_CONFIG_FILE")
    
    if [ -n "$ts_all" ]; then
        date_format_convert "ts_all" "$ts_all"
        check_and_resetprop "ro.build.version.security_patch" "$ts_all"
        check_and_resetprop "ro.vendor.build.security_patch" "$ts_all"
        check_and_resetprop "ro.system.build.security_patch" "$ts_all"
        return 0
    fi

    ts_system=$(get_config_var "system" "$TRICKY_STORE_CONFIG_FILE")
    ts_boot=$(get_config_var "boot" "$TRICKY_STORE_CONFIG_FILE")
    ts_vendor=$(get_config_var "vendor" "$TRICKY_STORE_CONFIG_FILE")
        
    [ -z "$ts_system" ] && [ -z "$ts_boot" ] && [ -z "$ts_vendor" ] && return 1

    if [ -n "$ts_system" ]; then
        check_and_resetprop "ro.build.version.security_patch" "$ts_system"
    fi

    if [ -n "$ts_boot" ]; then
        if [ "$ts_boot" = "yes" ]; then
            check_and_resetprop "ro.system.build.security_patch" "$ts_system"
        elif [ "$ts_boot" = "no" ]; then
            logowl "boot=no, skip disguising"
        else
            date_format_convert "ts_boot" "$ts_boot"
            check_and_resetprop "ro.system.build.security_patch" "$ts_boot"
        fi
    fi

    if [ -n "$ts_vendor" ]; then
        if [ "$ts_vendor" = "yes" ]; then
            check_and_resetprop "ro.system.build.security_patch" "$ts_system"
        elif [ "$ts_vendor" = "no" ]; then
            logowl "vendor=no, skip disguising"
        else
            date_format_convert "ts_vendor" "$ts_vendor"
            check_and_resetprop "ro.vendor.build.security_patch" "$ts_vendor"
        fi
    fi

    return 0

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

mirror_make_node() {

    node_path=$1

    if [ -z "$node_path" ]; then
        logowl "node_path is NOT ordered! (5)" "ERROR"
        return 5
    elif [ ! -e "$node_path" ]; then
        logowl "$node_path does NOT exist! (6)" "ERROR"
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
        logowl "mknod $mirror_node_path c 0 0 ($result_make_node)"
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

check_make_node_support() {
    
    logowl "$MOD_NAME is running on $ROOT_SOL"
    if [ "$DETECT_KSU" = true ] || [ "$DETECT_APATCH" = true ]; then
        logowl "Make Node support is present"
        MN_SUPPORT=true
    elif [ "$DETECT_MAGISK" = true ]; then
        if [ $MAGISK_V_VER_CODE -ge 28102 ]; then
            logowl "Make Node support is present"
            MN_SUPPORT=true
        else
            logowl "Make Node support is NOT present" "WARN"
            MN_SUPPORT=false
        fi
    fi

}

addon_d_slayer() {

    addon_d_path="/system/addon.d"

    addon_d_slay=$(get_config_var "addon_d_slay" "$CONFIG_FILE")
    [ -z "$addon_d_slay" ] && return 1

    if [ "$addon_d_slay" = false ]; then
        logowl "Flag addon_d_slay=false"
        return 0
    elif [ "$addon_d_slay" = true ]; then
        if [ "$MN_SUPPORT" = true ]; then
            logowl "Slay addon.d"
            mirror_make_node "$addon_d_path"
        else
            logowl "Flag MN_SUPPORT=false"
            logowl "Skip addon.d slayer"
        fi
    fi

}

install_recovery_script_slayer() {

    install_recovery_script_path="/system/bin/install-recovery.sh
/system/etc/install-recovery.sh
/system/etc/recovery-resource.dat
/system/recovery-from-boot.p
/system/vendor/bin/install-recovery.sh
/system/vendor/etc/install-recovery.sh
/system/vendor/recovery-from-boot.p
/system/vendor/etc/recovery-resource.dat"

    install_recovery_slay=$(get_config_var "install_recovery_slay" "$CONFIG_FILE")
    [ -z "$install_recovery_slay" ] && return 1

    if [ "$install_recovery_slay" = false ]; then
        logowl "Flag install_recovery_slay=false"
        return 0
    elif [ "$install_recovery_slay" = true ]; then
        if [ "$MN_SUPPORT" = true ]; then
            logowl "Slay install-recovery.sh"
            for irsh in $install_recovery_script_path; do
                if [ -f "$irsh" ]; then
                    logowl "Process: $irsh"
                    mirror_make_node "$irsh"
                fi
            done
        else
            logowl "Flag MN_SUPPORT=false"
            logowl "Skip install-recovery.sh slayer"
        fi
    fi

}

logowl_init "$LOG_DIR"
module_intro >> "$LOG_FILE"
show_system_info
print_line
logowl "Start post-fs-data.sh"
[ -n "$MODDIR" ] && rm -rf "$MODDIR/system"
print_line
logowl "Properties before disguise"
check_props
security_patch_info_disguiser
check_make_node_support
addon_d_slayer
install_recovery_script_slayer
print_line
set_permission_recursive "$MODDIR" 0 0 0755 0644
set_permission_recursive "$CONFIG_DIR" 0 0 0755 0644
logowl "Properties after disguise"
check_props
print_line
logowl "post-fs-data.sh case closed!"
