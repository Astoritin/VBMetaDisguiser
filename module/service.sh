#!/system/bin/sh
MODDIR=${0%/*}

. "$MODDIR/aa-util.sh"

CONFIG_DIR="/data/adb/vbmetadisguiser"
CONFIG_FILE="$CONFIG_DIR/vbmeta.conf"

LOG_DIR="$CONFIG_DIR/logs"
LOG_FILE="$LOG_DIR/vd_core_vbmeta_$(date +"%Y%m%dT%H%M%S").log"

MOD_INTRO="Disguise the properties of vbmeta, security patch date, encryption status and remove specific properties."

SLAIN_PROPS="$CONFIG_DIR/slain_props.prop"
TRICKY_STORE_CONFIG_FILE="/data/adb/tricky_store/security_patch.txt"

update_realtime=true
update_period=60
avb_version="2.0"
vbmeta_size="4096"
boot_hash="00000000000000000000000000000000"
props_slay=false
props_list=""

config_loader() {

    logowl "Load config"
    
    update_realtime=$(get_config_var "update_realtime" "$CONFIG_FILE")
    update_period=$(get_config_var "update_period" "$CONFIG_FILE")
    avb_version=$(get_config_var "avb_version" "$CONFIG_FILE")
    vbmeta_size=$(get_config_var "vbmeta_size" "$CONFIG_FILE")
    boot_hash=$(get_config_var "boot_hash" "$CONFIG_FILE")
    crypto_state=$(get_config_var "crypto_state" "$CONFIG_FILE")
    props_slay=$(get_config_var "props_slay" "$CONFIG_FILE")
    props_list=$(get_config_var "props_list" "$CONFIG_FILE")

}

props_slayer() {

    logowl "Slay props"

    if [ "$props_slay" = false ]; then
        logowl "Flag props_slay=false"
        if [ -f "$SLAIN_PROPS" ]; then
            logowl "$SLAIN_PROPS exists, restoring"
            resetprop -p -f "$SLAIN_PROPS"
            result_restore_props=$?
            logowl "resetprop -p -f $SLAIN_PROPS ($result_restore_props)"
            rm -f "$SLAIN_PROPS"
        fi
        return 0
    elif [ "$props_slay" = true ]; then
        logowl "Flag props_slay=true"
        for props_r in $props_list; do
            props_r_value="$(getprop $props_r)"
            if [ -n "$props_r_value" ]; then
                echo "${props_r}=$(getprop $props_r)" >> "$SLAIN_PROPS"
                resetprop -p -d $props_r
                result_slay_prop=$?
                logowl "resetprop -p -d $props_r ($result_slay_prop)"
            fi
        done
    fi
    clean_duplicate_items "$SLAIN_PROPS"
}

vbmeta_disguiser() {

    logowl "Disguise VBMeta partition props"

    resetprop -n "ro.boot.vbmeta.device_state" "locked"
    resetprop -n "ro.boot.vbmeta.hash_alg" "sha256"
    resetprop -n "ro.boot.vbmeta.digest" "$boot_hash"
    resetprop -n "ro.boot.vbmeta.size" "$vbmeta_size"
    resetprop -n "ro.boot.vbmeta.avb_version" "$avb_version"

}

encryption_disguiser(){

    logowl "Disguise Data partition props"

    [ -n "$crypto_state" ] && resetprop -n "ro.crypto.state" "$crypto_state"

}

soft_bootloader_spoof() {

    logowl "Spoof bootloader props"

    check_and_resetprop "ro.debuggable" "0"
    check_and_resetprop "ro.force.debuggable" "0"
    check_and_resetprop "ro.secure" "1"
    check_and_resetprop "ro.adb.secure" "1"

    check_and_resetprop "ro.boot.vbmeta.device_state" "locked"
    check_and_resetprop "ro.boot.verifiedbootstate" "green"

    check_and_resetprop "ro.warranty_bit" "0"
    check_and_resetprop "ro.boot.warranty_bit" "0"
    check_and_resetprop "ro.vendor.boot.warranty_bit" "0"
    check_and_resetprop "ro.vendor.warranty_bit" "0"

    check_and_resetprop "ro.boot.realmebootstate" "green"
    check_and_resetprop "ro.boot.realme.lockstate" "1"

    check_and_resetprop "ro.is_ever_orange" "0"
    check_and_resetprop "ro.secureboot.lockstate" "locked"

    for prop in $(resetprop | grep -oE 'ro.*.build.tags'); do
        check_and_resetprop "$prop" "release-keys"
    done
    for prop in $(resetprop | grep -oE 'ro.*.build.type'); do
        check_and_resetprop "$prop" "user"
    done
    check_and_resetprop "ro.build.type" "user"
    check_and_resetprop "ro.build.tags" "release-keys"

    check_and_resetprop "sys.oem_unlock_allowed" "0"
    check_and_resetprop "ro.oem_unlock_supported" "0"

    check_and_resetprop "init.svc.flash_recovery" "stopped"
    match_and_resetprop "ro.bootmode" "recovery" "unknown"
    match_and_resetprop "ro.boot.bootmode" "recovery" "unknown"
    match_and_resetprop "vendor.boot.bootmode" "recovery" "unknown"

}

module_status_update() {

    update_count=0
    
    desc_vbmeta_version=$(getprop 'ro.boot.vbmeta.avb_version')
    desc_vbmeta_digest="$(getprop 'ro.boot.vbmeta.digest' | cut -c1-16)"
    ellipsis="[..]"
    desc_vbmeta_hash_alg=$(getprop 'ro.boot.vbmeta.hash_alg')
    desc_vbmeta_digest="${desc_vbmeta_digest}${ellipsis}"
    desc_vbmeta_size=$(getprop 'ro.boot.vbmeta.size')
    desc_device_state=$(getprop 'ro.boot.vbmeta.device_state')
    desc_crypto_state=$(getprop 'ro.crypto.state')
    desc_security_patch=$(getprop 'ro.build.version.security_patch')

    if [ -z "$desc_vbmeta_digest" ] || echo "$desc_vbmeta_digest" | grep -qE '^0+$'; then
        desc_vbmeta="❓VBMeta: -"
    else
        desc_vbmeta="⚙️VBMeta: $desc_vbmeta_digest ($desc_vbmeta_hash_alg)"
        update_count=$((update_count + 1))
    fi

    desc_avb="AVB: ${desc_vbmeta_version:--} (${desc_device_state:--})"

    [ "$desc_crypto_state" = "encrypted" ] && icon_crypto="🔒"
    [ "$desc_crypto_state" = "unencrypted" ] && icon_crypto="🔓"
    [ "$desc_crypto_state" = "unsupported" ] && icon_crypto="❌"
    [ -n "$icon_crypto" ] && update_count=$((update_count + 1))
    desc_crypto="${icon_crypto}Data: $desc_crypto_state"

    if [ ! -f "$TRICKY_STORE_CONFIG_FILE" ] && [ ! -f "$CONFIG_FILE" ]; then
        desc_ts_sp="❌Security patch config does NOT exist"
    elif [ ! -s "$TRICKY_STORE_CONFIG_FILE" ] && [ ! -s "$CONFIG_FILE" ]; then
        desc_ts_sp="❓Security patch: -"
    else
        desc_ts_sp="⚡Security patch: $desc_security_patch"
        update_count=$((update_count + 1))
    fi

    slain_props_count=0
    desc_slain_props=""
    print_line
    logowl "Read slain properties" ">"
    while IFS= read -r line || [ -n "$line" ]; do
        line=$(printf '%s' "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        first_char=$(printf '%s' "$line" | cut -c1)
        [ -z "$line" ] && continue
        [ "$first_char" = "#" ] && continue
        logowl "slain prop $line"
        slain_props_count=$((slain_props_count + 1))
    done < "$SLAIN_PROPS"

    [ "$slain_props_count" -gt 0 ] && update_count=$((update_count + 1)) && desc_slain_props="📌$slain_props_count prop(s) slain"

    if [ "$update_count" -gt 0 ]; then
        if [ -n "$desc_slain_props" ]; then
            DESCRIPTION="[✅Done. $desc_vbmeta, $desc_ts_sp, $desc_crypto, $desc_slain_props] $MOD_INTRO"
        else
            DESCRIPTION="[✅Done. $desc_vbmeta, $desc_avb, $desc_ts_sp, $desc_crypto] $MOD_INTRO"
        fi
    else
        DESCRIPTION="[❌No effect. Maybe something went wrong?] $MOD_INTRO"
    fi
    update_config_var "description" "$DESCRIPTION" "$MODULE_PROP"

    logowl "Security patch date properties" ">"
    see_prop "ro.build.version.security_patch"
    see_prop "ro.system.build.security_patch"
    see_prop "ro.vendor.build.security_patch"
    logowl "VBMeta partition properties" ">"
    see_prop "ro.boot.vbmeta.device_state"
    see_prop "ro.boot.vbmeta.avb_version"
    see_prop "ro.boot.vbmeta.hash_alg"
    see_prop "ro.boot.vbmeta.size"
    see_prop "ro.boot.vbmeta.digest"
    logowl "Data partition properties" ">"
    see_prop "ro.crypto.state"

}

logowl_init "$LOG_DIR"
module_intro >> "$LOG_FILE"
show_system_info
print_line
config_loader
soft_bootloader_spoof
vbmeta_disguiser
encryption_disguiser
boot_count=0
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    boot_count=$((boot_count + 1))
    sleep 1
done
props_slayer
module_status_update
set_permission_recursive "$MODDIR" 0 0 0755 0644
set_permission_recursive "$CONFIG_DIR" 0 0 0755 0644
print_line
logowl "Case closed!"
logowl_clean "$LOG_DIR" 20

{
    MOD_REAL_TIME_DESC=""
    MOD_TURN_COUNT=0
    while true; do

        if [ "$update_realtime" = false ] || [ -f "$MODDIR/update" ]; then
            [ "$update_realtime" = false ] && logowl "Flag update_realtime=false"
            [ -f "$MODDIR/update" ] && logowl "Find flag update"
            logowl "Exit background task"
            exit 0
        fi

        [ ! -f "$CONFIG_FILE" ] && exit 1

        MOD_TURN_COUNT=$((MOD_TURN_COUNT + 1))
        logowl_init "$LOG_DIR"
        module_intro > "$LOG_FILE"
        show_system_info
        logowl "Current turn: ${MOD_TURN_COUNT}, update period: $update_period"
        print_line
        config_loader
        vbmeta_disguiser
        encryption_disguiser
        props_slayer
        module_status_update
        sleep "$update_period"
    done
} &
