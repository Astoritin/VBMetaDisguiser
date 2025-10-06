#!/system/bin/sh
MODDIR=${0%/*}

is_magisk() {

    if ! command -v magisk >/dev/null 2>&1; then
        return 1
    fi

    MAGISK_V_VER_NAME="$(magisk -v)"
    MAGISK_V_VER_CODE="$(magisk -V)"
    case "$MAGISK_V_VER_NAME" in
        *"-alpha"*) MAGISK_BRANCH_NAME="Alpha" ;;
        *"-lite"*)  MAGISK_BRANCH_NAME="Magisk Lite" ;;
        *"-kitsune"*) MAGISK_BRANCH_NAME="Kitsune Mask" ;;
        *"-delta"*) MAGISK_BRANCH_NAME="Magisk Delta" ;;
        *) MAGISK_BRANCH_NAME="Magisk" ;;
    esac
    DETECT_MAGISK="true"
    return 0

}

is_kernelsu() {
    if [ -n "$KSU" ]; then
        DETECT_KSU="true"
        ROOT_SOL="KernelSU"
        return 0
    fi
    return 1
}

is_apatch() {
    if [ -n "$APATCH" ]; then
        DETECT_APATCH="true"
        ROOT_SOL="APatch"
        return 0
    fi
    return 1
}

install_env_check() {

    MAGISK_BRANCH_NAME="Official"
    ROOT_SOL="Magisk"
    ROOT_SOL_COUNT=0

    is_kernelsu && ROOT_SOL_COUNT=$((ROOT_SOL_COUNT + 1))
    is_apatch && ROOT_SOL_COUNT=$((ROOT_SOL_COUNT + 1))
    is_magisk && ROOT_SOL_COUNT=$((ROOT_SOL_COUNT + 1))

    if [ "$DETECT_KSU" = "true" ]; then
        ROOT_SOL="KernelSU"
        ROOT_SOL_DETAIL="KernelSU (kernel:$KSU_KERNEL_VER_CODE, ksud:$KSU_VER_CODE)"
    elif [ "$DETECT_APATCH" = "true" ]; then
        ROOT_SOL="APatch"
        ROOT_SOL_DETAIL="APatch ($APATCH_VER_CODE)"
    elif [ "$DETECT_MAGISK" = "true" ]; then
        ROOT_SOL="Magisk"
        ROOT_SOL_DETAIL="$MAGISK_BRANCH_NAME (${MAGISK_VER_CODE:-$MAGISK_V_VER_CODE})"
    fi

    if [ "$ROOT_SOL_COUNT" -gt 1 ]; then
        ROOT_SOL="Multiple"
        ROOT_SOL_DETAIL="Multiple"
    elif [ "$ROOT_SOL_COUNT" -lt 1 ]; then
        ROOT_SOL="Unknown"
        ROOT_SOL_DETAIL="Unknown"
    fi

}

grep_config_var() {
    regex="s/^$1=//p"
    config_file="$2"

    [ -z "$config_file" ] && config_file="/system/build.prop"
    cat "$config_file" 2>/dev/null | dos2unix | sed -n "$regex" | head -n 1

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

update_config_var() {
    key_name="$1"
    file_path="$2"
    expected_value="$3"
    append_mode="${4:-false}"

    if [ -z "$key_name" ] || [ -z "$file_path" ]; then
        return 1
    elif [ ! -f "$file_path" ]; then
        return 2
    fi

    if grep -q "^${key_name}=" "$file_path"; then
        [ "$append_mode" = true ] && return 0
        sed -i "/^${key_name}=/c\\${key_name}=${expected_value}" "$file_path"
    else
        [ -n "$(tail -c1 "$file_path")" ] && echo >> "$file_path"
        printf '%s=%s\n' "$key_name" "$expected_value" >> "$file_path"
    fi

    result_update_value=$?
    return "$result_update_value"
}

remove_config_var() {
    key_name="$1"
    file_path="$2"

    if [ -z "$key_name" ] || [ -z "$file_path" ]; then
        return 1
    elif [ ! -f "$file_path" ]; then
        return 2
    fi

    sed -i "/^${key_name}=/d" "$file_path"
    return "$?"
}

show_system_info() {

    ui_print "- Device: $(getprop ro.product.brand) $(getprop ro.product.model) ($(getprop ro.product.device))"
    ui_print "- OS: Android $(getprop ro.build.version.release) (API $(getprop ro.build.version.sdk)), $(getprop ro.product.cpu.abi | cut -d '-' -f1)"
    ui_print "- Kernel: $(uname -r)"

}

file_compare() {
    file_a="$1"
    file_b="$2"
    
    [ -z "$file_a" ] || [ ! -f "$file_a" ] && return 2
    [ -z "$file_b" ] || [ ! -f "$file_b" ] && return 3
    
    hash_file_a=$(sha256sum "$file_a" | awk '{print $1}')
    hash_file_b=$(sha256sum "$file_b" | awk '{print $1}')
    
    [ "$hash_file_a" = "$hash_file_b" ] && return 0
    [ "$hash_file_a" != "$hash_file_b" ] && return 1

}

extract() {
    file=$1
    dir=$2
    junk=${3:-false}
    opts="-o"

    [ -z "$dir" ] && dir="$MODPATH"
    file_path="$dir/$file"
    hash_path="$TMPDIR/$file.sha256"

    if [ "$junk" = true ]; then
        opts="-oj"
        file_path="$dir/$(basename "$file")"
        hash_path="$TMPDIR/$(basename "$file").sha256"
    fi

    unzip $opts "$ZIPFILE" "$file" -d "$dir" >&2
    [ -f "$file_path" ] || abort "! $file does NOT exist"

    unzip $opts "$ZIPFILE" "${file}.sha256" -d "$TMPDIR" >&2
    [ -f "$hash_path" ] || abort "! ${file}.sha256 does NOT exist"

    expected_hash="$(cat "$hash_path")"
    calculated_hash="$(sha256sum "$file_path" | cut -d ' ' -f1)"

    if [ "$expected_hash" == "$calculated_hash" ]; then
        ui_print "- Verified $file" >&1
    else
        abort "! Failed to verify $file"
    fi
}

check_duplicate_items() {

    itemd=$1
    filed=$2

    if grep -q "^$itemd$" "$filed"; then
        return 1
    else
        return 0
    fi
}

clean_duplicate_items() {

    filed=$1

    [ -z "$filed" ] && return 1
    [ ! -f "$filed" ] && return 2

    awk '!seen[$0]++' "$filed" > "${filed}.tmp"
    mv "${filed}.tmp" "$filed"
    return 0

}

# VBMeta Disguiser specified functions

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
