#!/system/bin/sh
MODDIR=${0%/*}

. "$MODDIR/wanderer.sh"

CONFIG_DIR="/data/adb/vbmeta_disguiser"
CONFIG_FILE="$CONFIG_DIR/vbmeta.conf"

LOG_DIR="$CONFIG_DIR/logs"
LOG_FILE="$LOG_DIR/vd_core_vbmeta_$(date +"%Y%m%dT%H%M%S").log"

MOD_INTRO="Disguise VBMeta properties."

SLAIN_PROPS="$CONFIG_DIR/slain_props.prop"
TRICKY_STORE_CONFIG_FILE="/data/adb/tricky_store/security_patch.txt"

vbmeta_disguiser() {

    eco "Disguise VBMeta partition props"

    avb_version=$(get_config_var "avb_version" "$CONFIG_FILE") || avb_version="2.0"
    vbmeta_size=$(get_config_var "vbmeta_size" "$CONFIG_FILE") || vbmeta_size="4096"
    boot_hash=$(get_config_var "boot_hash" "$CONFIG_FILE") || boot_hash="00000000000000000000000000000000"

    print_var "avb_version" "vbmeta_size" "boot_hash"

    resetprop "ro.boot.vbmeta.device_state" "locked"
    resetprop "ro.boot.vbmeta.hash_alg" "sha256"
    [ -n "$boot_hash" ] && resetprop "ro.boot.vbmeta.digest" "$boot_hash"
    resetprop "ro.boot.vbmeta.size" "$vbmeta_size"
    resetprop "ro.boot.vbmeta.avb_version" "$avb_version"
}

encryption_disguiser(){
    crypto_state=$(get_config_var "crypto_state" "$CONFIG_FILE") || return 1

    print_var "crypto_state"

    eco "Disguise Data partition props"

    [ -n "$crypto_state" ] && resetprop -n "ro.crypto.state" "$crypto_state"

}

bootloader_properties_spoof() {
    bootloader_props_spoof=$(get_config_var "bootloader_props_spoof" "$CONFIG_FILE") || bootloader_props_spoof=false

    print_var "bootloader_props_spoof"

    if [ "$bootloader_props_spoof" = false ]; then
        eco "Skip bootloader properties spoofing"
    elif [ "$bootloader_props_spoof" = true ]; then
        eco "Spoof bootloader props"

        check_and_resetprop "ro.debuggable" "0"
        check_and_resetprop "ro.force.debuggable" "0"
        check_and_resetprop "ro.secure" "1"
        check_and_resetprop "ro.adb.secure" "1"

        check_and_resetprop "ro.boot.verifiedbootstate" "green"

        check_and_resetprop "ro.warranty_bit" "0"
        check_and_resetprop "ro.boot.warranty_bit" "0"
        check_and_resetprop "ro.vendor.boot.warranty_bit" "0"
        check_and_resetprop "ro.vendor.warranty_bit" "0"

        check_and_resetprop "ro.boot.realmebootstate" "green"
        check_and_resetprop "ro.boot.realme.lockstate" "1"

        check_and_resetprop "ro.is_ever_orange" "0"
        check_and_resetprop "ro.secureboot.lockstate" "locked"

        check_and_resetprop "sys.oem_unlock_allowed" "0"
        check_and_resetprop "ro.oem_unlock_supported" "0"

        check_and_resetprop "init.svc.flash_recovery" "stopped"
        match_and_resetprop "ro.bootmode" "recovery" "unknown"
        match_and_resetprop "ro.boot.bootmode" "recovery" "unknown"
        match_and_resetprop "vendor.boot.bootmode" "recovery" "unknown"
    fi
}

build_type_spoof_as_user_release() {
    build_type_spoof=$(get_config_var "build_type_spoof" "$CONFIG_FILE") || build_type_spoof=false
    custom_build_fingerprint=$(get_config_var "custom_build_fingerprint" "$CONFIG_FILE")
    print_var "build_type_spoof" "custom_build_fingerprint"

    if [ "$build_type_spoof" = false ]; then
        eco "Skip build type properties spoofing"
        return 0
    elif [ "$build_type_spoof" = true ]; then
        eco "Spoof build type props"
        
        check_and_resetprop "ro.build.type" "user"
        for prop in $(resetprop | grep -oE 'ro.*.build.tags'); do
            check_and_resetprop "$prop" "release-keys"
        done

        check_and_resetprop "ro.build.tags" "release-keys"
        for prop in $(resetprop | grep -oE 'ro.*.build.type'); do
            check_and_resetprop "$prop" "user"
        done
        
        if [ -n "$custom_build_fingerprint" ]; then
            check_and_resetprop "ro.build.fingerprint" "$custom_build_fingerprint"
        else
            build_fingerprint=$(resetprop 'ro.build.fingerprint')
            print_var "build_fingerprint"
            build_fingerprint=$(printf '%s' "$build_fingerprint" | sed -e 's/userdebug/user/g' -e 's/test-keys/release-keys/g')
            print_var "build_fingerprint"
            check_and_resetprop "ro.build.fingerprint" "$build_fingerprint"
        fi
        for prop in $(resetprop | grep -oE 'ro.*.build.fingerprint'); do
            if [ -n "$custom_build_fingerprint" ]; then
                check_and_resetprop "$prop" "$custom_build_fingerprint"
            else
                build_fingerprint=$(resetprop "$prop" | sed -e 's/userdebug/user/g' -e 's/test-keys/release-keys/g')
                eco "Process fingerprint prop: $prop=$build_fingerprint"
                check_and_resetprop "$prop" "$build_fingerprint"
            fi
        done 
    fi
}

props_slayer() {
    props_slay=$(get_config_var "props_slay" "$CONFIG_FILE") || props_slay=false
    restore_after_disable=$(get_config_var "restore_after_disable" "$CONFIG_FILE") || restore_after_disable=true
    print_var "props_slay" "restore_after_disable"

    if [ "$props_slay" = false ]; then
        eco "Flag props_slay=false"
        if [ -f "$SLAIN_PROPS" ]; then
            eco "$SLAIN_PROPS exists"
            if [ "$restore_after_disable" = true ]; then
                resetprop -p -f "$SLAIN_PROPS"
                result_restore_props=$?
                eco "resetprop -p -f $SLAIN_PROPS ($result_restore_props)"
                if [ "$result_restore_props" -eq 0 ]; then
                    eco "Remove slain properties backup file"
                    rm -f "$SLAIN_PROPS"
                fi
            else
                eco "Skip restoring props"
                rm -f "$SLAIN_PROPS"
            fi
        fi
        return 0
    elif [ "$props_slay" = true ]; then
        eco "Slay props"
        props_list=$(get_config_var "props_list" "$CONFIG_FILE") || props_list=""
        print_var "props_list"
        for props_r in $props_list; do
            props_r_value="$(resetprop $props_r)"
            if [ -n "$props_r_value" ]; then
                echo "${props_r}=${props_r_value}" >> "$SLAIN_PROPS"
                resetprop -p -d $props_r
                result_slay_prop=$?
                eco "resetprop -p -d $props_r ($result_slay_prop)"
            fi
        done
    fi
    clean_duplicate_items "$SLAIN_PROPS"
}

outdated_pihooks_pixelprops_slayer() {
    outdated_pi_props_slay=$(get_config_var "outdated_pi_props_slay" "$CONFIG_FILE") || outdated_pi_props_slay=false

    if [ "$outdated_pi_props_slay" = false ]; then
        eco "Skip Outdated Pihooks/Pixelprops properties slaying"
        return 0
    elif [ "$outdated_pi_props_slay" = true ]; then
        eco "Slay outdated Pihooks/Pixelprops properties"
        props_list=$(resetprop | grep -E "(pihook|pixelprops|spoof\.gms|entryhooks)" | sed -r "s/^\[([^]]+)\].*/\1/")
        print_var "props_list"
        for prop in $props_list; do
            resetprop -p -d "$prop"
            result_slay_prop=$?
            eco "resetprop -p -d $prop ($result_slay_prop)"
        done
    fi

}

vbmeta_modstate_update() {
    DESC_TMPDIR="$CONFIG_DIR/vd_desc.tmp"

    eco "Update module description"

    get_prop() { getprop "$1" 2>/dev/null || echo "-"; }
    is_empty_or_zero() { [ -z "$1" ] || echo "$1" | grep -qE '^0+$'; }

    vbmeta_digest=$(get_prop 'ro.boot.vbmeta.digest' | cut -c1-16)
    vbmeta_hash_alg=$(get_prop 'ro.boot.vbmeta.hash_alg')
    vbmeta_version=$(get_prop 'ro.boot.vbmeta.avb_version')
    device_state=$(get_prop 'ro.boot.vbmeta.device_state')
    crypto_state=$(get_prop 'ro.crypto.state')
    security_patch=$(get_prop 'ro.build.version.security_patch')

    {
        if is_empty_or_zero "$vbmeta_digest"; then
            echo "❓VBMeta digest is not set"
        else
            echo "⚙️VBMeta hash: ${vbmeta_digest}[..] ($vbmeta_hash_alg)"
        fi

        echo "AVB ${vbmeta_version} (${device_state})"

        if [ ! -f "$TRICKY_STORE_CONFIG_FILE" ] && [ ! -f "$CONFIG_FILE" ]; then
            echo "❌Security patch date config does NOT exist"
        else
            echo "⚡Security patch: $security_patch"
        fi

        case "$crypto_state" in
            encrypted)   echo "🔒Data: encrypted" ;;
            unencrypted) echo "🔓Data: unencrypted" ;;
            unsupported) echo "❌Data: unsupported" ;;
            *)           echo "❓Data: $crypto_state" ;;
        esac

        slain_count=0
        [ -s "$SLAIN_PROPS" ] && slain_count=$(grep -vE '^[[:space:]]*(#|$)' "$SLAIN_PROPS" 2>/dev/null | wc -l)
        [ "$slain_count" -gt 0 ] && echo "📌${slain_count} prop(s) slain"
    } > "$DESC_TMPDIR"

    desc_parts=$(awk 'ORS=", "' "$DESC_TMPDIR" | sed 's/,[[:space:]]*$//')
    DESCRIPTION="[$desc_parts] $MOD_INTRO"
    update_config_var "description" "$MODULE_PROP" "$DESCRIPTION" 
    rm -f "$DESC_TMPDIR"

}

print_prop() {
    prop_name=$1
    prop_current_value=$(getprop "$prop_name")

    if [ -n "$prop_current_value" ]; then
        eco "$prop_name=$prop_current_value"
        return 0
    elif [ -z "$prop_current_value" ]; then
        eco "$prop_name="
        return 1
    fi

}

print_result() {

    eco "Security patch date properties" ">"
    print_prop "ro.build.version.security_patch"
    print_prop "ro.system.build.security_patch"
    print_prop "ro.vendor.build.security_patch"
    eco "VBMeta partition properties" ">"
    print_prop "ro.boot.vbmeta.device_state"
    print_prop "ro.boot.vbmeta.avb_version"
    print_prop "ro.boot.vbmeta.hash_alg"
    print_prop "ro.boot.vbmeta.size"
    print_prop "ro.boot.vbmeta.digest"
    eco "Data partition properties" ">"
    print_prop "ro.crypto.state"

}

if [ "$FROM_ACTION" = true ]; then
    eco "Process from action/open button"
    bootloader_properties_spoof
    build_type_spoof_as_user_release
    vbmeta_disguiser
    encryption_disguiser
    props_slayer
    vbmeta_modstate_update
    return 0
fi

eco_init "$LOG_DIR"
module_intro >> "$LOG_FILE"
show_system_info
print_line
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 1
done
bootloader_properties_spoof
build_type_spoof_as_user_release
vbmeta_disguiser
encryption_disguiser
props_slayer
outdated_pihooks_pixelprops_slayer
vbmeta_modstate_update
print_result
print_line
eco "Case closed!"
eco_clean "$LOG_DIR" 20
