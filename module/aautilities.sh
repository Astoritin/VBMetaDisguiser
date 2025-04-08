#!/system/bin/sh
MODDIR=${0%/*}

is_kernelsu() {
    if [ -n "$KSU" ]; then
        logowl "Install from KernelSU"
        logowl "KernelSU version: $KSU_KERNEL_VER_CODE (kernel) + $KSU_VER_CODE (ksud)"
        ROOT_SOL="KernelSU (kernel:$KSU_KERNEL_VER_CODE, ksud:$KSU_VER_CODE)"
        if { type magisk; } || [ -n "$APATCH" ]; then
            logowl "Detect multiple Root solutions!" "WARN"
            ROOT_SOL="Multiple"
        fi
        return 0
    fi
    return 1
}

is_apatch() {
    if [ -n "$APATCH" ]; then
        logowl "Install from APatch"
        logowl "APatch version: $APATCH_VER_CODE"
        ROOT_SOL="APatch ($APATCH_VER_CODE)"
        if { type magisk; } || [ -n "$KSU" ]; then
            logowl "Detect multiple Root solutions!" "WARN"
            ROOT_SOL="Multiple"
        fi
        return 0
    fi
    return 1
}

is_magisk() {
    if [ -n "$MAGISK_VER_CODE" ] || [ -n "$(magisk -v || magisk -V)" ]; then
        MAGISK_V_VER_NAME="$(magisk -v)"
        MAGISK_V_VER_CODE="$(magisk -V)"
        case "$MAGISK_VER $MAGISK_V_VER_NAME" in
            *"-alpha"*) MAGISK_BRANCH_NAME="Magisk Alpha" ;;
            *"-lite"*)  MAGISK_BRANCH_NAME="Magisk Lite" ;;
            *"-kitsune"*) MAGISK_BRANCH_NAME="Kitsune Mask" ;;
            *"-delta"*) MAGISK_BRANCH_NAME="Magisk Delta" ;;
            *) MAGISK_BRANCH_NAME="Magisk" ;;
        esac
        ROOT_SOL="$MAGISK_BRANCH_NAME (${MAGISK_VER_CODE:-$MAGISK_V_VER_CODE})"
        logowl "Install from $ROOT_SOL"
        if [ -n "$KSU" ] || [ -n "$APATCH" ]; then
            logowl "Detect multiple Root solutions!" "WARN"
            ROOT_SOL="Multiple"
        fi
        return 0
    fi
    return 1
}

is_recovery() {
    ROOT_SOL="Recovery"
    logowl "Install module in Recovery mode is not supported, especially for KernelSU / APatch!" "FATAL"
    logowl "Please install this module in Magisk / KernelSU / APatch APP!" "FATAL"
    abort
}

install_env_check() {

    MAGISK_BRANCH_NAME="Official"
    ROOT_SOL="Magisk"

    if ! is_kernelsu && ! is_apatch && ! is_magisk; then
        is_recovery
    fi
}


module_intro() {

    install_env_check
    print_line
    logowl "$MOD_NAME"
    logowl "By $MOD_AUTHOR"
    logowl "Version: $MOD_VER"
    logowl "Root solution: $ROOT_SOL"
    logowl "Current time stamp: $(date +"%Y-%m-%d %H:%M:%S")"
    logowl "Current module dir: $MODDIR"
    print_line

}

init_logowl() {

    LOG_DIR="$1"
    if [ -z "$LOG_DIR" ]; then
        logowl "LOG_DIR is not provided!" "ERROR"
        return 1
    fi

    if [ ! -d "$LOG_DIR" ]; then
        logowl "Log dir does NOT exist"
        mkdir -p "$LOG_DIR" || {
            logowl "Failed to create $LOG_DIR" "ERROR" >&2
            return 2
        }
        logowl "Created $LOG_DIR"
    else
        logowl "$LOG_DIR already exists"
    fi

    logowl "Logowl initialized"

}

logowl() {

    LOG_MSG="$1"
    LOG_LEVEL="$2"

    if [ -z "$LOG_MSG" ]; then
        echo "! LOG_MSG is not provided yet!"
        return 1
    fi

    case "$LOG_LEVEL" in
        "TIPS") LOG_LEVEL="*" ;;
        "WARN") LOG_LEVEL="- Warn:" ;;
        "ERROR") LOG_LEVEL="! ERROR:" ;;
        "FATAL") LOG_LEVEL="× FATAL:" ;;
        "SPACE") LOG_LEVEL=" " ;;
        "NONE") LOG_LEVEL="_" ;;
        *) LOG_LEVEL="-" ;;
    esac

    if [ -n "$LOG_FILE" ]; then
        if [ "$LOG_LEVEL" = "! ERROR:" ] || [ "$LOG_LEVEL" = "× FATAL:" ]; then
            echo "----------------------------------------------------" >> "$LOG_FILE"
            echo "$LOG_LEVEL $LOG_MSG" >> "$LOG_FILE"
            echo "----------------------------------------------------" >> "$LOG_FILE"
        elif [ "$LOG_LEVEL" = "_" ]; then
            echo "$LOG_MSG" >> "$LOG_FILE"
        else
            echo "$LOG_LEVEL $LOG_MSG" >> "$LOG_FILE"
        fi
    else
        if command -v ui_print >/dev/null 2>&1 && [ "$BOOTMODE" ]; then
            if [ "$LOG_LEVEL" = "! ERROR:" ] || [ "$LOG_LEVEL" = "× FATAL:" ]; then
                ui_print "----------------------------------------------------"
                ui_print "$LOG_LEVEL $LOG_MSG"
                ui_print "----------------------------------------------------"
            elif [ "$LOG_LEVEL" = "_" ]; then
                ui_print "$LOG_MSG"
            else
                ui_print "$LOG_LEVEL $LOG_MSG"
            fi
        else
            echo "$LOG_LEVEL $LOG_MSG"
        fi
    fi
}

print_line() {

    length=${1:-50}

    line=$(printf "%-${length}s" | tr ' ' '-')
    logowl "$line" "NONE"
}

init_variables() {
    key="$1"
    config_file="$2"

    if [ ! -f "$config_file" ]; then
        logowl "Configuration file $config_file does NOT exist" "ERROR" >&2
        return 1
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
                    if (in_quote) {
                        print "Error: Unclosed quote for key " key > "/dev/stderr"
                        exit 1
                    }
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

    awk_exit_status=$?

    case $awk_exit_status in
        1)
            logowl "Key '$key' not found or unclosed quote in $config_file" "ERROR" >&2
            return 1
            ;;
        0)  ;;
        *)  logowl "Error processing key '$key' in $config_file" "ERROR" >&2
            return 1
            ;;
    esac

    value=$(printf "%s" "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    if check_value_safety "$key" "$value"; then
        echo "$value"
        return 0
    else
        result=$?
        return "$result"
    fi
}

check_value_safety(){

    key="$1"
    value="$2"

    if [ -z "$value" ]; then
        logowl "Detect empty value (code: 1)" "WARN"
        return 1
    fi

    value=$(printf "%s" "$value" | sed 's/'\''/'\\\\'\'''\''/g' | sed 's/[$;&|<>`"()]/\\&/g')

    if [ "$value" = "true" ] || [ "$value" = "false" ]; then
        logowl "Verified $key=$value (boolean)" "TIPS"
        return 0
    fi

    first_char=$(printf '%s' "$value" | cut -c1)
    if [ "$first_char" = "#" ]; then
        logowl "Detect comment symbol (code: 2)" "WARN"
        return 2
    fi

    value=$(echo "$value" | cut -d'#' -f1 | xargs)

    regex='^[a-zA-Z0-9/_\. -]*$'
    dangerous_chars='[`$();|<>]'

    if echo "$value" | grep -Eq "$dangerous_chars"; then
        logowl "Key '$key' contains potential dangerous characters" "ERROR" >&2
        return 3
    fi
    if ! echo "$value" | grep -Eq "$regex"; then
        logowl "Key '$key' contains illegal characters" "WARN" >&2
        return 4
    fi

    logowl "Verified $key=$value" "TIPS"
    return 0
}

verify_variables() {
  
    config_var_name="$1"
    config_var_value="$2"
    validation_pattern="$3"
    default_value="${4:-}"
    script_var_name=$(echo "$config_var_name" | tr '[:lower:]' '[:upper:]')

    if [ -n "$config_var_value" ] && echo "$config_var_value" | grep -qE "$validation_pattern"; then
        export "$script_var_name"="$config_var_value"
        logowl "Set $script_var_name=$config_var_value" "TIPS"
    else
        logowl "Config var value is empty or does NOT match the pattern" "WARN"
        logowl "Unavailable var: $script_var_name=$config_var_value"

        if [ -n "$default_value" ]; then
            if eval "[ -z \"\${$script_var_name+x}\" ]"; then
                logowl "Using default value for $script_var_name: $default_value" "TIPS"
                export "$script_var_name"="$default_value"
            else
                logowl "Variable $script_var_name already set, skipping default value" "WARN"
            fi
        else
            logowl "No default value provided for $script_var_name, keeping its current state" "TIPS"
        fi
    fi
}

update_config_value() {

    key_name="$1"
    key_value="$2"
    file_path="$3"

    if [ -z "$key_name" ] || [ -z "$key_value" ] || [ -z "$file_path" ]; then
        logowl "Key name/value/file path is NOT provided yet!" "ERROR"
        return 1
    elif [ ! -f "$file_path" ]; then
        logowl "$file_path is NOT a valid file!" "ERROR"
        return 2
    fi
    logowl "Update $key_name: $key_value"
    sed -i "/^${key_name}=/c\\${key_name}=${key_value}" "$file_path"

    result_update_value=$?
    if [ $result_update_value -eq 0 ]; then
        logowl "Succeeded (code: $result_update_value)"
    else
        logowl "Failed to update $key_name=$key_value into $file_path (code: $result_update_value)" "WARN"
    fi

}

debug_print_values() {

    print_line
    logowl "All Environment Variables"
    print_line
    env | sed 's/^/- /'
    print_line

    logowl "All Shell Variables"
    print_line
    ( set -o posix; set ) | sed 's/^/- /'
    print_line
}

show_system_info() {

    logowl "Device: $(getprop ro.product.brand) $(getprop ro.product.model) ($(getprop ro.product.device))"
    logowl "OS: Android $(getprop ro.build.version.release) (API $(getprop ro.build.version.sdk)), $(getprop ro.product.cpu.abi | cut -d '-' -f1)"

}

file_compare() {

    file_a="$1"
    file_b="$2"
    if [ -z "$file_a" ] || [ -z "$file_b" ]; then
      logowl "Value a or value b does NOT exist!" "WARN"
      return 2
    fi
    if [ ! -f "$file_a" ]; then
      logowl "a is NOT a file!" "WARN"
      return 3
    fi
    if [ ! -f "$file_b" ]; then
      logowl "b is NOT a file!" "WARN"
      return 3
    fi
    hash_file_a=$(sha256sum "$file_a" | awk '{print $1}')
    hash_file_b=$(sha256sum "$file_b" | awk '{print $1}')
    if [ "$hash_file_a" == "$hash_file_b" ]; then
        return 0
    else
        return 1
    fi
}

abort_verify() {

    if [ -n "$VERIFY_DIR" ] && [ -d "$VERIFY_DIR" ] && [ "$VERIFY_DIR" != "/" ]; then
        rm -rf "$VERIFY_DIR"
    fi
    print_line
    logowl "$1" "WARN"
    logowl "Please try to download again or get it from official source!" "WARN"
    abort "This zip may be corrupted or have been maliciously modified!"

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
    [ -f "$file_path" ] || abort_verify "$file does NOT exist!"
    logowl "Extract $file → $file_path" >&1

    unzip $opts "$zip" "$file.sha256" -d "$VERIFY_DIR" >&2
    [ -f "$hash_path" ] || abort_verify "$file.sha256 does NOT exist!"

    expected_hash="$(cat "$hash_path")"
    calculated_hash="$(sha256sum "$file_path" | cut -d ' ' -f1)"

    if [ "$expected_hash" == "$calculated_hash" ]; then
        logowl "Verified $file" >&1
    else
        abort_verify "Failed to verify $file"
    fi
}

clean_old_logs() {
 
    log_dir="$1"
    files_max="$2"
    
    if [ -z "$log_dir" ] || [ ! -d "$log_dir" ]; then
        logowl "$log_dir is not found or is not a directory!" "ERROR"
        return
    fi

    if [ -z "$files_max" ]; then
        files_max=30
    fi

    files_count=$(ls -1 "$log_dir" | wc -l)
    if [ "$files_count" -gt "$files_max" ]; then
        logowl "Detect too many log files" "WARN"
        logowl "$files_count files, current max allowed: $files_max"
        logowl "Clearing old logs"
        ls -1t "$log_dir" | tail -n +$((files_max + 1)) | while read -r file; do
            rm -f "$log_dir/$file"
        done
        logowl "Cleared!"
    else
        logowl "Detect $files_count files in $log_dir"
    fi
}
