if ! command -v abort >/dev/null 2>&1; then
    logowl "Detect abort does NOT available!" "WARN"
    abort() {
        echo "[!] $1"
        exit 1
    }
fi

is_kernelsu() {
    if [ -n "$KSU" ]; then
        logowl "Install from KernelSU"
        logowl "KernelSU version: $KSU_KERNEL_VER_CODE (kernel) + $KSU_VER_CODE (ksud)"
        ROOT_SOL="KernelSU (kernel:$KSU_KERNEL_VER_CODE, ksud:$KSU_VER_CODE)"
        if [ -n "$(which magisk)" ]; then
            logowl "Detect multiple Root implements!" "WARN"
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
        logowl "Installing from $ROOT_SOL"
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
    # install_env_check: a function to check the current root solution
    # Magisk branch name is Official by default
    # Root solution is Magisk by default

    MAGISK_BRANCH_NAME="Official"
    ROOT_SOL="Magisk"

    if ! is_kernelsu && ! is_apatch && ! is_magisk; then
        is_recovery
    fi
}


module_intro() {
    # module_intro: a function to show module basic info

    MODULE_PROP="${MODDIR}/module.prop"
    MOD_NAME="$(sed -n 's/^name=\(.*\)/\1/p' "$MODULE_PROP")"
    MOD_AUTHOR="$(sed -n 's/^author=\(.*\)/\1/p' "$MODULE_PROP")"
    MOD_VER="$(sed -n 's/^version=\(.*\)/\1/p' "$MODULE_PROP") ($(sed -n 's/^versionCode=\(.*\)/\1/p' "$MODULE_PROP"))"

    install_env_check
    print_line

    logowl "$MOD_NAME"
    logowl "By $MOD_AUTHOR"
    logowl "Version: $MOD_VER"
    logowl "Root solution: $ROOT_SOL"
    logowl "Current time stamp: $(date +"%Y-%m-%d %H:%M:%S")"
    print_line
}

init_logowl() {
    # init_logowl: a function to initiate the log directory
    # to make sure the log directory exist

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
    # logowl: a function to format the log output
    # LOG_MSG: the log message you need to print
    # LOG_LEVEL: the level of this log message
    LOG_MSG="$1"
    LOG_LEVEL="${2:-DEF}"

    if [ -z "$LOG_MSG" ]; then
        echo "! LOG_MSG is not provided yet!"
        return 1
    fi

    case "$LOG_LEVEL" in
        "TIPS") LOG_LEVEL="*" ;;
        "WARN") LOG_LEVEL="- Warn:" ;;
        "ERROR") LOG_LEVEL="! ERROR:" ;;
        "FATAL") LOG_LEVEL="× FATAL:" ;;
        "NONE") LOG_LEVEL=" " ;;
        *) LOG_LEVEL="-" ;;
    esac

    if [ -z "$LOG_FILE" ]; then
        if command -v ui_print >/dev/null 2>&1 && [ "$BOOTMODE" ]; then
            ui_print "$LOG_LEVEL $LOG_MSG" 2>/dev/null
        else
            echo "$LOG_LEVEL $LOG_MSG"
        fi
    else
        if [ "$LOG_LEVEL" = "! ERROR:" ] || [ "$LOG_LEVEL" = "× FATAL:" ]; then
            print_line >> "$LOG_FILE"
        fi
        echo "$LOG_LEVEL $LOG_MSG" >> "$LOG_FILE"
        if [ "$LOG_LEVEL" = "! ERROR:" ] || [ "$LOG_LEVEL" = "× FATAL:" ]; then
            print_line >> "$LOG_FILE"
        fi
    fi
}

print_line() {
    # print_line: a function to print separate line
    length=${1:-50}
    line=$(printf "%-${length}s" | tr ' ' '-')
    echo "$line"
}

init_variables() {
    # init_variables: a function to initiate variables
    # key: the key name
    # config_file: the path and filename of the key it located
    # value: the value of the key
    key="$1"
    config_file="$2"
    value

    if [ ! -f "$config_file" ]; then
        logowl "Configuration file $config_file does NOT exist" "ERROR" >&2
        return 1
    fi

    # Fetch the value from config file
    value=$(sed -n "s/^$key=\(.*\)/\1/p" "$config_file" | tr -d '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  
    if check_value_safety "$key" "$value"; then
        echo "$value"
        return 0
    else
        result=$?
        return "$result"
    fi

}

check_value_safety(){
    # check_value_safety: a function to check the safety of value
    key="$1"
    value="$2"

    # Check if the value is null
    if [ -z "$value" ]; then
        logowl "Detect empty value, status code: 1" "WARN"
        return 1
    fi

    # If the value is start with "#", then take this line as comment line
    if [ "${value:0:1}" = "#" ]; then
        logowl "Detect comment symbol, status code: 2" "WARN"
        return 2
    fi

    # Special handling for boolean values
    if [ "$value" = "true" ] || [ "$value" = "false" ]; then
        logowl "Verified $key=$value (boolean)" "TIPS"
        return 0
    fi

    # Escape the value to safe one
    value=$(printf "%s" "$value" | sed 's/'\''/'\\\\'\'''\''/g' | sed 's/[$;&|<>`"()]/\\&/g')

    # fetch the main content before symbol "#"
    value=$(echo "$value" | cut -d'#' -f1 | xargs)

    # regex: the regular expression to match the safe variable
    regex='^[a-zA-Z0-9/_\. -]*$'
    dangerous_chars='[`$();|<>]'

    # Check for dangerous characters
    if echo "$value" | grep -Eq "$dangerous_chars"; then
        logowl "Key '$key' contains potential dangerous characters" "ERROR" >&2
        return 3
    fi
    if ! echo "$value" | grep -Eq "$regex"; then
        logowl "Key '$key' contains illegal characters" "WARN" >&2
        return 4
    fi

    # If all checks pass
    logowl "Verified $key=$value" "TIPS"
    return 0
}

verify_variables() {
    # verify_variables: a function to verify the availability of variables and export it
    # config_var_name: the name of variable
    # config_var_value: the value of variable
    # validation_pattern: the regex pattern for checking the validity of the variable value
    # default_value (optional): if the ordered value is unavailable, the value should be set as default
    # script_var_name: the name of the variable in uppercase for exporting
  
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

        # Check if a default value is provided
        if [ -n "$default_value" ]; then
            # Use eval to check if the variable is already set
            if eval "[ -z \"\${$script_var_name+x}\" ]"; then
                logowl "Using default value for $script_var_name: $default_value" "TIPS"
                export "$script_var_name"="$default_value"
            else
                logowl "Variable $script_var_name already set, skipping default value" "WARN"
            fi
        else
            logowl "No default value provided for $script_var_name, keeping its current state" "TIPS"
            # Do nothing if no default value is provided
        fi
    fi
}

update_module_description() {
    # update_module_description: a function to update the value of the key "description"
    # DESCRIPTION: the description you want to update to
    # MODULE_PROP: the path of module.prop you want to update the description

    DESCRIPTION="$1"
    MODULE_PROP="$2"
    if [ -z "$DESCRIPTION" ] || [ -z "$MODULE_PROP" ]; then
      logowl "DESCRIPTION or MODULE_PROP is not provided yet!" "ERROR"
      return 3
    fi
    logowl "Update description: $DESCRIPTION"
    sed -i "/^description=/c\description=$DESCRIPTION" "$MODULE_PROP"
}

debug_print_values() {
    # debug_print_values: print the environment info and variables during this script running

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
    # show_system_info: to show the Device, Android and RAM info.

    logowl "Device: $(getprop ro.product.brand) $(getprop ro.product.model) ($(getprop ro.product.device))"
    logowl "OS: Android $(getprop ro.build.version.release) (API $(getprop ro.build.version.sdk)), $(getprop ro.product.cpu.abi | cut -d '-' -f1)"
    mem_info=$(free -m)
    ram_total=$(echo "$mem_info" | awk '/Mem/ {print $2}')
    ram_used=$(echo "$mem_info" | awk '/Mem/ {print $3}')
    ram_free=$((ram_total - ram_used))
    swap_total=$(echo "$mem_info" | awk '/Swap/ {print $2}')
    swap_used=$(echo "$mem_info" | awk '/Swap/ {print $3}')
    swap_free=$(echo "$mem_info" | awk '/Swap/ {print $4}')
    logowl "RAM: ${ram_total}MB  Used:${ram_used}MB  Free:${ram_free}MB"
    logowl "SWAP: ${swap_total}MB  Used:${swap_used}MB  Free:${swap_free}MB"
}


file_compare() {
    # file_compare: a function to compare whether file a and file b is same or not
    # file_a: the path of file a
    # file_b: the path of file b

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
    # logowl "File a: $hash_file_a"
    # logowl "File b: $hash_file_b"
    if [ "$hash_file_a" == "$hash_file_b" ]; then
        # logowl "The hash of file a is equal to file b, they are the same files!"
        return 0
    else
        # logowl "The hash of file a is NOT equal to file b, they are NOT the same files!"
        return 1
    fi
}

abort_verify() {
    # abort_verify: a function to abort verify because of detecting hash does NOT match

    rm -rf "$VERIFY_DIR"
    print_line
    logowl "$1" "WARN"
    logowl "This zip may be corrupted or have been maliciously modified!" "WARN"
    logowl "Please try to download again or get it from official source!" "WARN"
    abort "**************************************************"
}

extract() {
    # extract: a function to extract zip and verify the hash
    # zip: the path of zip file
    # file: the filename you want to extract from zip file
    # dir: the dir you want to extract to
    #
    # junk_paths: whether preserve the file's folders in zip file or not
    # For example, a file in zip file is: /META/AA/config.ini
    # if false, file config.ini will be extracted into /(target dir)/META/AA/config.ini
    # if true, file config.ini will be extracted into /(target dir)/config.ini

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
    logowl "Extract $file -> $file_path" >&1

    unzip $opts "$zip" "$file.sha256" -d "$VERIFY_DIR" >&2
    [ -f "$hash_path" ] || abort_verify "$file.sha256 does NOT exist!"

    expected_hash="$(cat "$hash_path")"
    calculated_hash="$(sha256sum "$file_path" | cut -d ' ' -f1)"

    if [ "$expected_hash" == "$calculated_hash" ]; then
      logowl "Verified $file" >&1
    else
      abort_verify "Failed to verify $file"
      rm -rf "$VERIFY_DIR"
    fi
}

set_module_files_perm() {
    # set_module_files_perm: set module files's permission
    # only use in installing module

    logowl "Setting permissions"
    set_perm_recursive "$MODPATH" 0 0 0755 0644
}

clean_old_logs() {
    # clean_old_logs: a function to clean logs dir as detecting too many logs
    # log_dir: the log directory you want to clean
    # files_max: the max value of files you allow to keep in logs dir
 
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
