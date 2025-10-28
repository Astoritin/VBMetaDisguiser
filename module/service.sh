#!/system/bin/sh
MODDIR=${0%/*}

. "$MODDIR/wanderer.sh"

CONFIG_DIR="/data/adb/vbmeta_disguiser"
CONFIG_FILE="$CONFIG_DIR/vbmeta.conf"

MOD_INTRO="Disguise VBMeta properties."
MODULE_PROP="$MODDIR/module.prop"

SLAIN_PROPS="$CONFIG_DIR/slain_props.prop"
TRICKY_STORE_CONFIG_FILE="/data/adb/tricky_store/security_patch.txt"

vbmeta_disguiser() {

    avb_version=$(get_config_var "avb_version" "$CONFIG_FILE") || avb_version="2.0"
    vbmeta_size=$(get_config_var "vbmeta_size" "$CONFIG_FILE") || vbmeta_size="4096"
    boot_hash=$(get_config_var "boot_hash" "$CONFIG_FILE")

    resetprop "ro.boot.vbmeta.device_state" "locked"
    resetprop "ro.boot.vbmeta.hash_alg" "sha256"
    [ -n "$boot_hash" ] && resetprop "ro.boot.vbmeta.digest" "$boot_hash"
    resetprop "ro.boot.vbmeta.size" "$vbmeta_size"
    resetprop "ro.boot.vbmeta.avb_version" "$avb_version"

}

encryption_disguiser(){

    crypto_state=$(get_config_var "crypto_state" "$CONFIG_FILE") || return 1

    [ -n "$crypto_state" ] && resetprop -n "ro.crypto.state" "$crypto_state"

}

bootloader_properties_spoof() {

    bootloader_props_spoof=$(get_config_var "bootloader_props_spoof" "$CONFIG_FILE") || bootloader_props_spoof=false

    if [ "$bootloader_props_spoof" = false ]; then
        return 0
    elif [ "$bootloader_props_spoof" = true ]; then
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

    if [ "$build_type_spoof" = false ]; then
        return 0
    elif [ "$build_type_spoof" = true ]; then        
        check_and_resetprop "ro.build.type" "user"
        for prop in $(resetprop | grep -oE 'ro.*.build.tags'); do
            check_and_resetprop "$prop" "release-keys"
        done

        check_and_resetprop "ro.build.tags" "release-keys"
        for prop in $(resetprop | grep -oE 'ro.*.build.type'); do
            check_and_resetprop "$prop" "user"
        done

        build_flavor=$(resetprop 'ro.build.flavor')
        if [ -n "$build_flavor" ]; then
            build_flavor=$(echo "$build_flavor" | sed -e 's/userdebug/user/g')
            check_and_resetprop "ro.build.flavor" "$build_flavor"
        fi
        
        if [ -n "$custom_build_fingerprint" ]; then
            check_and_resetprop "ro.build.fingerprint" "$custom_build_fingerprint"
        else
            build_fingerprint=$(resetprop 'ro.build.fingerprint' | sed -e 's/userdebug/user/g' -e 's/test-keys/release-keys/g')
            check_and_resetprop "ro.build.fingerprint" "$build_fingerprint"
        fi
        for prop in $(resetprop | grep -oE 'ro.*.build.fingerprint'); do
            if [ -n "$custom_build_fingerprint" ]; then
                check_and_resetprop "$prop" "$custom_build_fingerprint"
            else
                build_fingerprint=$(resetprop "$prop" | sed -e 's/userdebug/user/g' -e 's/test-keys/release-keys/g')
                check_and_resetprop "$prop" "$build_fingerprint"
            fi
        done
    fi

}

props_slayer() {

    props_list=$1

    [ -z "$props_list" ] && return 1

    for prop in $props_list; do
        prop_value="$(resetprop "$prop")"
        if [ -n "$prop_value" ]; then
            echo "$prop=$prop_value" >> "$SLAIN_PROPS"
            resetprop -p -d "$prop"
        fi
    done

}

props_and_outdated_pihooks_pixelprops_slayer() {

    props_slay=$(get_config_var "props_slay" "$CONFIG_FILE") || props_slay=false
    restore_after_disable=$(get_config_var "restore_after_disable" "$CONFIG_FILE") || restore_after_disable=true
    outdated_pi_props_slay=$(get_config_var "outdated_pi_props_slay" "$CONFIG_FILE") || outdated_pi_props_slay=false

    if [ "$props_slay" = false ] && [ "$outdated_pi_props_slay" = false ]; then
        if [ -f "$SLAIN_PROPS" ] && [ "$restore_after_disable" = true ]; then
            resetprop -p -f "$SLAIN_PROPS" && rm -f "$SLAIN_PROPS"
        else
            rm -f "$SLAIN_PROPS"
        fi
        return 0
    fi

    slay_list=""
    pi_list=""
    [ "$props_slay" = true ] && slay_list=$(get_config_var "props_list" "$CONFIG_FILE")
    [ "$outdated_pi_props_slay" = true ] && pi_list=$(resetprop | grep -E "(pihook|pixelprops|spoof\.gms|entryhooks)" | sed -r "s/^\[([^]]+)\].*/\1/")

    props_list=$(printf '%s%s%s\n' "$slay_list" "${slay_list:+$'\n'}" "$pi_list")
    props_slayer "$props_list"

    clean_duplicate_items "$SLAIN_PROPS"

}

vbmeta_modstate_update() {

    DESC_TMPDIR="$CONFIG_DIR/vd_desc.tmp"

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

if [ "$FROM_ACTION" = true ]; then
    echo "- Executing from action/open button"
    vbmeta_disguiser
    build_type_spoof_as_user_release
    encryption_disguiser
    props_and_outdated_pihooks_pixelprops_slayer
    vbmeta_modstate_update
    return 0
fi

bootloader_properties_spoof
vbmeta_disguiser

while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 1
done

build_type_spoof_as_user_release
encryption_disguiser
props_and_outdated_pihooks_pixelprops_slayer
vbmeta_modstate_update
