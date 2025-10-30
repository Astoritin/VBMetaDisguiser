#!/system/bin/sh
MODDIR=${0%/*}

CONFIG_DIR="/data/adb/vbmeta_disguiser"
CONFIG_FILE="$CONFIG_DIR/vbmeta.conf"

check_and_resetprop() {

    prop_name=$1
    prop_expect_value=$2
    prop_current_value=$(resetprop "$prop_name")

    [ -z "$prop_current_value" ] && return 1

    [ "$prop_current_value" = "$prop_expect_value" ] && return 0
    
    if [ "$prop_current_value" != "$prop_expect_value" ]; then
        resetprop "$prop_name" "$prop_expect_value"
    fi

}

match_and_resetprop() {

    prop_name="$1"
    prop_contains_keyword="$2"
    prop_expect_value="$3"
    prop_current_value=$(resetprop "$prop_name")

    [ -z "$prop_current_value" ] && return 1
    [ -z "$prop_contains_keyword" ] && return 1
    [ -z "$prop_expect_value" ] && return 1
    
    if echo "$prop_current_value" | grep -q "$prop_contains_keyword"; then
        resetprop "$prop_name" "$prop_expect_value"
    fi

}

get_config_var() {
    key=$1
    config_file=$2

    if [ -z "$key" ] || [ -z "$config_file" ]; then
        return 1
    elif [ ! -f "$config_file" ]; then
        return 2
    fi
    
    value=$(awk -v key="$key" '
        BEGIN {
            key_regex = "^" key "="
            found = 0
            in_quote = 0
            value = ""
        }
        $0 ~ key_regex && !found {
            sub(key_regex, "")
            remaining = $0

            sub(/^[[:space:]]*/, "", remaining)

            if (remaining ~ /^"/) {
                in_quote = 1
                remaining = substr(remaining, 2)

                if (match(remaining, /"([[:space:]]*)$/)) {
                    value = substr(remaining, 1, RSTART - 1)
                    in_quote = 0
                } else {
                    value = remaining
                    while ((getline remaining) > 0) {
                        if (match(remaining, /"([[:space:]]*)$/)) {
                            line_part = substr(remaining, 1, RSTART - 1)
                            value = value "\n" line_part
                            in_quote = 0
                            break
                        } else {
                            value = value "\n" remaining
                        }
                    }
                    if (in_quote) exit 1
                }
                found = 1
            } else {
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", remaining)
                value = remaining
                found = 1
            }
            if (found) exit 0
        }
        END {
            if (!found) exit 1
            gsub(/[[:space:]]+$/, "", value)
            print value
        }
    ' "$config_file")

    awk_exit_state=$?
    case $awk_exit_state in
        1)  return 5
            ;;
        0)  ;;
        *)  return 6
            ;;
    esac

    value=$(echo "$value" | dos2unix | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/'\''/'\\\\'\'''\''/g' | sed 's/[$;&|<>`"()]/\\&/g')

    if [ -n "$value" ]; then
        echo "$value"
        return 0
    else
        return 1
    fi
}

bootloader_properties_spoof() {

    bootloader_props_spoof=$(get_config_var "bootloader_props_spoof" "$CONFIG_FILE") || bootloader_props_spoof=false

    if [ "$bootloader_props_spoof" = false ]; then
        return 0
    elif [ "$bootloader_props_spoof" = true ]; then

        check_and_resetprop "ro.boot.verifiedbootstate" "green"
        check_and_resetprop "vendor.boot.verifiedbootstate" "green"
        check_and_resetprop "ro.boot.vbmeta.device_state" "locked"
        check_and_resetprop "vendor.boot.vbmeta.device_state" "locked"
    
        check_and_resetprop "ro.debuggable" "0"
        check_and_resetprop "ro.force.debuggable" "0"
        check_and_resetprop "ro.secure" "1"
        check_and_resetprop "ro.adb.secure" "1"

        check_and_resetprop "ro.warranty_bit" "0"
        check_and_resetprop "ro.boot.warranty_bit" "0"
        check_and_resetprop "ro.vendor.boot.warranty_bit" "0"
        check_and_resetprop "ro.vendor.warranty_bit" "0"

        check_and_resetprop "ro.boot.realmebootstate" "green"
        check_and_resetprop "ro.boot.realme.lockstate" "1"

        check_and_resetprop "ro.is_ever_orange" "0"
        check_and_resetprop "ro.secureboot.lockstate" "locked"
        check_and_resetprop "ro.boot.flash.locked" "1"
        check_and_resetprop "ro.boot.veritymode" "enforcing"

        check_and_resetprop "sys.oem_unlock_allowed" "0"
        check_and_resetprop "ro.oem_unlock_supported" "0"

        check_and_resetprop "init.svc.flash_recovery" "stopped"
        match_and_resetprop "ro.bootmode" "recovery" "unknown"
        match_and_resetprop "ro.boot.bootmode" "recovery" "unknown"
        match_and_resetprop "vendor.boot.bootmode" "recovery" "unknown"
    fi

}

bootloader_properties_spoof