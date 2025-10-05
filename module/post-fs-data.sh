#!/system/bin/sh
MODDIR=${0%/*}

. "$MODDIR/wanderer.sh"

CONFIG_DIR="/data/adb/vbmeta_disguiser"
CONFIG_FILE="$CONFIG_DIR/vbmeta.conf"

LOG_DIR="$CONFIG_DIR/logs"
LOG_FILE="$LOG_DIR/vd_core_patch_$(date +"%Y%m%dT%H%M%S").log"

TRICKY_STORE_CONFIG_FILE="/data/adb/tricky_store/security_patch.txt"

date_format_convert() {
    date_to_convert=$1
    [ -z "$date_to_convert" ] && return 1

    eco "date_to_convert=${date_to_convert} (before)"

    case $date_to_convert in
        [0-9][0-9][0-9][0-9][0-9][0-9])
            eco "Matches case: xxxxxx"
            year=$(expr "$date_to_convert" : '\([0-9]\{4\}\)')
            month=$(expr "$date_to_convert" : '.*\([0-9]\{2\}\)$')
            formatted_date="${year}-${month}-05"
            ;;
        [0-9][0-9][0-9][0-9]-[0-9][0-9])
            eco "Matches case: xxxx-xx"
            formatted_date="${date_to_convert}-05"
            ;;
        [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9])
            eco "Matches case: xxxxxxxx"
            year=$(expr "$date_to_convert" : '\([0-9]\{4\}\)')
            month=$(expr "$date_to_convert" : '.*\([0-9]\{2\}\)[0-9]\{2\}$')
            day=$(expr "$date_to_convert" : '.*\([0-9]\{2\}\)$')
            formatted_date="${year}-${month}-${day}"
            ;;
        [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9])
            eco "Matches case: xxxx-xx-xx"
            formatted_date=$date_to_convert
            ;;
        *)  eco "Illegal value date_to_convert=${date_to_convert}" "W"
            return 1;;
    esac

    if echo "$formatted_date" | awk '
        BEGIN { ok=1 }
        !/^[0-9]{4}-[0-9]{2}-[0-9]{2}$/ { ok=0; exit }
        {
            split($0, d, "-")
            y=d[1]; m=d[2]; dd=d[3]
            if (m < 1 || m > 12 || dd < 1 || dd > 31) ok=0
            if (m == 2) max = (y % 4 == 0 && y % 100 != 0 || y % 400 == 0) ? 29 : 28
            else if (m == 4 || m == 6 || m == 9 || m == 11) max = 30
            else max = 31
            if (dd > max) ok=0
        }
        END { exit !ok }
    '
    then
        printf '%s\n' "$formatted_date"
    else
        return 1
    fi
}

ts_sp_quick_set() {
    date_qs=$1

    [ -z "$date_qs" ] && return 1
    eco "Start quick set process"
    eco "date_qs=${date_qs}"
    check_and_resetprop "ro.build.version.security_patch" "$date_qs"
    check_and_resetprop "ro.vendor.build.security_patch" "$date_qs"
    check_and_resetprop "ro.system.build.security_patch" "$date_qs"

}

ts_sp_partition_set() {
    partition_state=$1
    partition_date=$2

    if [ -n "$partition_state" ]; then
        eco "Start partition props quick set process"
        eco "partition_state=${partition_state} (before)"
        eco "partition_date=${partition_date}"
        if [ "$partition_state" = "yes" ] && [ -n "$partition_date" ]; then
            check_and_resetprop "ro.system.build.security_patch" "$partition_date"
        elif [ "$partition_state" = "no" ]; then
            eco "partition_state=no, skip disguising"
        else
            partition_state=$(date_format_convert "$partition_state")
            eco "partition_state=${partition_state} (after)"
            check_and_resetprop "ro.system.build.security_patch" "$partition_state"
        fi
    fi
}

ts_sp_config_simple() {
    ts_date=$(grep -v '^#' "$TRICKY_STORE_CONFIG_FILE" | grep -Eo '[0-9]+' | head -n 1)

    eco "Find config file using simple mode"

    ts_date=$(date_format_convert "$ts_date")
    eco "ts_date=${ts_date} (before)"
    if [ -n "$ts_date" ]; then
        eco "ts_date=${ts_date} (after)"
        ts_sp_quick_set "$ts_date"
    fi
}

ts_sp_config_advanced() {
    ts_all=$(get_config_var "all" "$TRICKY_STORE_CONFIG_FILE")
    print_var "ts_all"

    eco "Find config file using advanced mode"
    
    if [ -n "$ts_all" ]; then
        ts_all=$(date_format_convert "$ts_all")
        eco "ts_all=${ts_all} (after convert)"
        ts_sp_quick_set "$ts_all"
        return 0
    fi

    ts_system=$(get_config_var "system" "$TRICKY_STORE_CONFIG_FILE")
    print_var "ts_system"

    if [ -n "$ts_system" ]; then
        ts_system=$(date_format_convert "$ts_system")
        eco "ts_system=${ts_system} (after convert)"
        check_and_resetprop "ro.build.version.security_patch" "$ts_system"
    fi

    ts_boot=$(get_config_var "boot" "$TRICKY_STORE_CONFIG_FILE")
    print_var "ts_boot"
    ts_sp_partition_set "$ts_boot" "$ts_system"

    ts_vendor=$(get_config_var "vendor" "$TRICKY_STORE_CONFIG_FILE")
    print_var "ts_vendor"
    ts_sp_partition_set "$ts_vendor" "$ts_system"
}

security_patch_info_disguiser() {
    security_patch_disguise=$(get_config_var "security_patch_disguise" "$CONFIG_FILE") || security_patch_disguise=false
    print_var "security_patch_disguise"

    if [ -z "$security_patch_disguise" ]; then
        eco "Security patch disguiser is NOT set yet"
        eco "skip processing"
        return 1
    elif [ "$security_patch_disguise" = false ]; then
        eco "Security patch properties is disabled"
        return 0
    elif [ "$security_patch_disguise" = true ]; then
        eco "Disguise security patch properties"
        if [ -f "$TRICKY_STORE_CONFIG_FILE" ]; then
            TS_FILE_CONTENT=$(cat "$TRICKY_STORE_CONFIG_FILE")
            if printf '%s\n' "$TS_FILE_CONTENT" | grep -q '='; then
                ts_sp_config_advanced
            else
                ts_sp_config_simple
            fi
        elif [ ! -f "$TRICKY_STORE_CONFIG_FILE" ] && [ -f "$CONFIG_FILE" ]; then
            eco "Tricky Store security patch config file" "W"
            eco "$TRICKY_STORE_CONFIG_FILE does NOT exist"
            eco "$MOD_NAME will try to fetch config from $CONFIG_FILE"    
            TRICKY_STORE_CONFIG_FILE="$CONFIG_FILE"
            ts_sp_config_advanced
        else
            eco "Both Tricky Store config and" "W"
            eco "VBMeta Disguiser config does NOT exist"
        fi
    fi

}

mirror_make_node() {
    node_path=$1

    if [ -z "$node_path" ]; then
        eco "Node path is NOT defined (5)" "E"
        return 5
    elif [ ! -e "$node_path" ]; then
        eco "$node_path does NOT exist (6)" "E"
        return 6
    fi

    node_path_parent_dir=$(dirname "$node_path")
    mirror_parent_dir="$MODDIR$node_path_parent_dir"
    mirror_node_path="$MODDIR$node_path"

    if [ ! -d "$mirror_parent_dir" ]; then
        mkdir -p "$mirror_parent_dir"
        eco "Create parent dir $mirror_parent_dir"
    fi

    if [ ! -e "$mirror_node_path" ]; then
        mknod "$mirror_node_path" c 0 0
        result_make_node="$?"
        eco "mknod $mirror_node_path c 0 0 ($result_make_node)"
        if [ $result_make_node -eq 0 ]; then
            return 0
        else
            return $result_make_node
        fi
    else
        eco "Node $mirror_node_path exists already"
        return 0
    fi
}

check_make_node_support() {
    if [ "$DETECT_KSU" = true ] || [ "$DETECT_APATCH" = true ]; then
        eco "Make Node support is present"
        MN_SUPPORT=true
    elif [ "$DETECT_MAGISK" = true ]; then
        if [ $MAGISK_V_VER_CODE -ge 28102 ]; then
            eco "Make Node support is present"
            MN_SUPPORT=true
        else
            MN_SUPPORT=false
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

    install_recovery_slay=$(get_config_var "install_recovery_slay" "$CONFIG_FILE") || install_recovery_slay=false
    print_var "install_recovery_slay"
    if [ -z "$install_recovery_slay" ]; then
        eco "install-recovery.sh slayer is NOT set yet"
        eco "skip processing"
        return 1
    elif [ "$install_recovery_slay" = false ]; then
        eco "Skip install-recovery.sh slayer"
        return 0
    elif [ "$install_recovery_slay" = true ]; then
        check_make_node_support
        if [ "$MN_SUPPORT" = true ]; then
            eco "Slaying install-recovery.sh"
            for irsh in $install_recovery_script_path; do
                if [ -f "$irsh" ]; then
                    eco "Process $irsh"
                    mirror_make_node "$irsh"
                fi
            done
        else
            eco "Your root solution does NOT support Make Node mode"
            eco "$MOD_NAME will skip slaying install-recovery.sh"
        fi
    fi
}

[ -d "$LOG_DIR" ] && eco_clean "$LOG_DIR"
eco_init "$LOG_DIR"
module_intro >> "$LOG_FILE"
show_system_info
print_line
[ -n "$MODDIR" ] && rm -rf "$MODDIR/system"
security_patch_info_disguiser
install_recovery_script_slayer
print_line
eco "Case closed!"
