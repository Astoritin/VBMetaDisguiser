#!/system/bin/sh
MODDIR=${0%/*}

is_magisk() {

    if ! command -v magisk >/dev/null 2>&1; then
        return 1
    fi

    MAGISK_V_VER_NAME="$(magisk -v)"
    MAGISK_V_VER_CODE="$(magisk -V)"
    case "$MAGISK_V_VER_NAME" in
        *"-alpha"*) MAGISK_BRANCH_NAME="Magisk Alpha" ;;
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

logowl_init() {
    LOG_DIR="$1"

    [ -z "$LOG_DIR" ] && return 1
    [ ! -d "$LOG_DIR" ] && mkdir -p "$LOG_DIR" && logowl "Created $LOG_DIR"

}

logowl_clean() {
    log_dir="$1"
    files_max="$2"
    
    [ -z "$log_dir" ] || [ ! -d "$log_dir" ] && return 1
    [ -z "$files_max" ] && files_max=30

    files_count=$(ls -1 "$log_dir" | wc -l)
    if [ "$files_count" -gt "$files_max" ]; then
        ls -1t "$log_dir" | tail -n +$((files_max + 1)) | while read -r file; do
            rm -f "$log_dir/$file"
        done
    fi
    return 0
}

logowl() {
    LOG_MSG="$1"
    LOG_MSG_LEVEL="$2"
    LOG_MSG_PREFIX=""

    [ -z "$LOG_MSG" ] && return 1

    case "$LOG_MSG_LEVEL" in
        "WARN") LOG_MSG_PREFIX="- Warn: " ;;
        "ERROR") LOG_MSG_PREFIX="! ERROR: " ;;
        "FATAL") LOG_MSG_PREFIX="× FATAL: " ;;
        ">") LOG_MSG_PREFIX="> " ;;
        "*" ) LOG_MSG_PREFIX="* " ;; 
        " ") LOG_MSG_PREFIX="  " ;;
        "-") LOG_MSG_PREFIX="" ;;
        *) LOG_MSG_PREFIX="- " ;;
    esac

    if [ -n "$LOG_FILE" ]; then
        if [ "$LOG_MSG_LEVEL" = "ERROR" ] || [ "$LOG_MSG_LEVEL" = "FATAL" ]; then
            echo "---------------------------------------------------" >> "$LOG_FILE"
            echo "${LOG_MSG_PREFIX}${LOG_MSG}" >> "$LOG_FILE"
            echo "---------------------------------------------------" >> "$LOG_FILE"
        elif [ "$LOG_MSG_LEVEL" = "-" ]; then
            echo "$LOG_MSG" >> "$LOG_FILE"
        else
            echo "${LOG_MSG_PREFIX}${LOG_MSG}" >> "$LOG_FILE"
        fi
    else
        if command -v ui_print >/dev/null 2>&1; then
            if [ "$LOG_MSG_LEVEL" = "ERROR" ] || [ "$LOG_MSG_LEVEL" = "FATAL" ]; then
                ui_print "---------------------------------------------------"
                ui_print "${LOG_MSG_PREFIX}${LOG_MSG}"
                ui_print "---------------------------------------------------"
            elif [ "$LOG_MSG_LEVEL" = "-" ]; then
                ui_print "$LOG_MSG"
            else
                ui_print "${LOG_MSG_PREFIX}${LOG_MSG}"
            fi
        else
            echo "${LOG_MSG_PREFIX}${LOG_MSG}"
        fi
    fi
}

print_line() {

    length=${1:-51}
    symbol=${2:--}

    line=$(printf "%-${length}s" | tr ' ' "$symbol")
    logowl "$line" "-"

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
        logowl "Key or config file path is NOT ordered" "WARN"
        return 1
    elif [ ! -f "$config_file" ]; then
        logowl "$config_file is NOT a file" "WARN"
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
        1)  logowl "Error in fetching value for $key (1)" "WARN"
            return 5
            ;;
        0)  ;;
        *)  logowl "Unexpected error ($awk_exit_state)" "WARN"
            return 6
            ;;
    esac

    value=$(echo "$value" | dos2unix | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/'\''/'\\\\'\'''\''/g' | sed 's/[$;&|<>`"()]/\\&/g')

    if [ -n "$value" ]; then
        logowl "Set $key=$value" ">"
        echo "$value"
        return 0
    else
        logowl "Key $key does NOT exist in file $config_file" "WARN"
        return 1
    fi
}

update_config_var() {
    key_name="$1"
    key_value="$2"
    file_path="$3"

    if [ -z "$key_name" ] || [ -z "$key_value" ] || [ -z "$file_path" ]; then
        return 1
    elif [ ! -f "$file_path" ]; then
        return 2
    fi

    sed -i "/^${key_name}=/c\\${key_name}=${key_value}" "$file_path"
    result_update_value=$?
    return "$result_update_value"

}

debug_print_values() {

    print_line
    logowl "All Environment variables"
    print_line
    env | sed 's/^/- /'
    print_line
    logowl "All Shell variables"
    print_line
    ( set -o posix; set ) | sed 's/^/- /'
    print_line

}

show_system_info() {

    logowl "Device: $(getprop ro.product.brand) $(getprop ro.product.model) ($(getprop ro.product.device))"
    logowl "OS: Android $(getprop ro.build.version.release) (API $(getprop ro.build.version.sdk)), $(getprop ro.product.cpu.abi | cut -d '-' -f1)"
    logowl "Kernel: $(uname -r)"
}

module_intro() {

    MODULE_PROP="$MODDIR/module.prop"
    MOD_NAME="$(grep_config_var "name" "$MODULE_PROP")"
    MOD_AUTHOR="$(grep_config_var "author" "$MODULE_PROP")"
    MOD_VER="$(grep_config_var "version" "$MODULE_PROP") ($(grep_config_var "versionCode" "$MODULE_PROP"))"

    install_env_check
    print_line
    logowl "$MOD_NAME"
    logowl "By $MOD_AUTHOR"
    logowl "Version: $MOD_VER"
    logowl "Root: $ROOT_SOL_DETAIL"
    print_line

}

file_compare() {
    file_a="$1"
    file_b="$2"
    
    [ -z "$file_a" ] || [ -z "$file_b" ] && return 2
    [ ! -f "$file_a" ] || [ ! -f "$file_b" ] && return 3
    
    hash_file_a=$(sha256sum "$file_a" | awk '{print $1}')
    hash_file_b=$(sha256sum "$file_b" | awk '{print $1}')
    
    [ "$hash_file_a" = "$hash_file_b" ] && return 0
    [ "$hash_file_a" != "$hash_file_b" ] && return 1

}

abort_verify() {

    [ -n "$VERIFY_DIR" ] && [ -d "$VERIFY_DIR" ] && [ "$VERIFY_DIR" != "/" ] && rm -rf "$VERIFY_DIR"
    logowl "$1" "ERROR"
    abort "This zip may be corrupted or has been maliciously modified!"

}

extract() {

    zip=$1
    file=$2
    dir=$3
    junk_paths=${4:-false}
    opts="-o"
    [ $junk_paths = true ] && opts="-oj"

    file_path=""
    hash_path=""
    if [ $junk_paths = true ]; then
        file_path="$dir/$(basename "$file")"
        hash_path="$VERIFY_DIR/$(basename "$file").sha256"
    else
        file_path="$dir/$file"
        hash_path="$VERIFY_DIR/$file.sha256"
    fi

    unzip $opts "$zip" "$file" -d "$dir" >&2
    [ -f "$file_path" ] || abort_verify "$file does NOT exist"

    unzip $opts "$zip" "$file.sha256" -d "$VERIFY_DIR" >&2
    [ -f "$hash_path" ] || abort_verify "$file.sha256 does NOT exist"

    expected_hash="$(cat "$hash_path")"
    calculated_hash="$(sha256sum "$file_path" | cut -d ' ' -f1)"

    if [ "$expected_hash" == "$calculated_hash" ]; then
        logowl "Verified $file" >&1
    else
        abort_verify "Failed to verify file $file"
    fi
}

set_permission() {

    chown $2:$3 $1 || return 1    
    chmod $4 $1 || return 1
    
    selinux_content=$5
    [ -z "$selinux_content" ] && selinux_content=u:object_r:system_file:s0
    chcon $selinux_content $1 || return 1

}

set_permission_recursive() {

    find $1 -type d 2>/dev/null | while read dir; do
        set_permission $dir $2 $3 $4 $6
    done

    find $1 -type f -o -type l 2>/dev/null | while read file; do
        set_permission $file $2 $3 $5 $6
    done

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

see_prop() {
    prop_name=$1
    prop_current_value=$(getprop "$prop_name")

    if [ -n "$prop_current_value" ]; then
        logowl "$prop_name=$prop_current_value"
        return 0
    elif [ -z "$prop_current_value" ]; then
        logowl "$prop_name="
        return 1
    fi

}

check_and_resetprop() {

    prop_name=$1
    prop_expect_value=$2
    prop_current_value=$(resetprop "$prop_name")

    [ -z "$prop_current_value" ] && return 1

    [ "$prop_current_value" = "$prop_expect_value" ] && return 0
    
    if [ "$prop_current_value" != "$prop_expect_value" ]; then
        resetprop "$prop_name" "$prop_expect_value"
        result_check_and_resetprop=$?
        logowl "resetprop $prop_name $prop_expect_value ($result_check_and_resetprop)"
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
        result_check_and_resetprop=$?
        logowl "resetprop $prop_name $prop_expect_value ($result_check_and_resetprop)"
    fi

}

fetch_package_path_from_pm() {
    package_name=$1
    output_pm=$(pm path "$package_name")

    [ -z "$output_pm" ] && return 1

    package_path=$(echo "$output_pm" | cut -d':' -f2- | sed 's/^://' )

    echo "$package_path"    
}

uninstall_package() {

    package_name="$1"

    pm uninstall "$package_name"
    result_uninstall_package=$?

    return "$result_uninstall_package"

}

install_package() {

    package_path="$1"

    cp "$package_path" "$TMP_DIR"

    package_basename=$(basename "$package_path")
    package_tmp="$TMP_DIR/$package_basename"

    pm install -i "com.android.vending" "$package_tmp"
    result_install_package=$?

    rm -f "$package_tmp"
    return "$result_install_package"    

}
