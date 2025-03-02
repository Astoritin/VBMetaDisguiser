VERIFY_DIR="$TMPDIR/.aa_bhd_verify"
mkdir "$VERIFY_DIR"

install_env_check() {
  local CONFIG_DIR="$1"
  local MAGISK_BRANCH_NAME="Official"
  local ROOT_IMP="Magisk"
  if [[ "$KSU" ]]; then
    echo "- Install from KernelSU"
    echo "- KernelSU version: $KSU_KERNEL_VER_CODE (kernel) + $KSU_VER_CODE (ksud)"
    ROOT_IMP="KernelSU (kernel:$KSU_KERNEL_VER_CODE, ksud:$KSU_VER_CODE)"
    if [[ "$(which magisk)" ]]; then
      echo "! Detect multiple Root implements!"
      ROOT_IMP="Multiple"
    fi
  elif [[ "$APATCH" ]]; then
    echo "- Install from APatch"
    echo "- APatch version: $APATCH_VER_CODE"
    ROOT_IMP="APatch ($APATCH_VER_CODE)"
  elif [[ "$MAGISK_VER_CODE" || -n "$(magisk -v || magisk -V)" ]]; then
    MAGISK_V_VER_NAME="$(magisk -v)"
    MAGISK_V_VER_CODE="$(magisk -V)"
    if [[ "$MAGISK_VER" == *"-alpha"* || "$MAGISK_V_VER_NAME" == *"-alpha"* ]]; then
      MAGISK_BRANCH_NAME="Magisk Alpha"
    elif [[ "$MAGISK_VER" == *"-lite"* || "$MAGISK_V_VER_NAME" == *"-lite"* ]]; then
      MAGISK_BRANCH_NAME="Magisk Lite"
    elif [[ "$MAGISK_VER" == *"-kitsune"* || "$MAGISK_V_VER_NAME" == *"-kitsune"* ]]; then
      MAGISK_BRANCH_NAME="Kitsune Mask"
    elif [[ "$MAGISK_VER" == *"-delta"* || "$MAGISK_V_VER_NAME" == *"-delta"* ]]; then
      MAGISK_BRANCH_NAME="Magisk Delta"
    else
      MAGISK_BRANCH_NAME="Magisk"
    fi
    ROOT_IMP="$MAGISK_BRANCH_NAME (${MAGISK_VER_CODE:-$MAGISK_V_VER_CODE})"
    echo "- Install from $ROOT_IMP"
  else
    ROOT_IMP="Recovery"
    echo "! Install module in Recovery mode is not support!"
    echo "! Especially for KernelSU / APatch!"
    abort "! Please install this module in Magisk / KernelSU / APatch APP!"
  fi
  if [ -n "$CONFIG_DIR" ]; then
    if [ ! -d "$CONFIG_DIR" ]; then
        echo "- $CONFIG_DIR does not exist"
        mkdir -p "$CONFIG_DIR" || abort "! Failed to create $CONFIG_DIR!"
        echo "- Create $CONFIG_DIR"
    else
        echo "- $CONFIG_DIR already existed"
    fi
    if ! grep -q "^root=" "$CONFIG_DIR/status.info"; then
    echo "root=" >> "$CONFIG_DIR/status.info"
    fi
    sed -i "/^root=/c\root=$ROOT_IMP" "$CONFIG_DIR/status.info"
  fi
}

show_system_info(){
  echo "- Device: $(getprop ro.product.brand) $(getprop ro.product.model) ($(getprop ro.product.device))"
  echo "- Android $(getprop ro.build.version.release) (API $API), $ARCH"
  mem_info=$(free -m)
  ram_total=$(echo "$mem_info" | awk '/Mem/ {print $2}')
  ram_used=$(echo "$mem_info" | awk '/Mem/ {print $3}')
  ram_free=$((ram_total - ram_used))
  swap_total=$(echo "$mem_info" | awk '/Swap/ {print $2}')
  swap_used=$(echo "$mem_info" | awk '/Swap/ {print $3}')
  swap_free=$(echo "$mem_info" | awk '/Swap/ {print $4}')
  echo "- RAM Space: ${ram_total}MB  Used:${ram_used}MB  Free:${ram_free}MB"
  echo "- SWAP Space: ${swap_total}MB  Used:${swap_used}MB  Free:${swap_free}MB"
}

abort_verify() {
  echo "! $1"
  echo "! This zip may be corrupted or have been maliciously modified!"
  abort "! Please try to download again or get it from official source!"
}

extract() {
  zip=$1
  file=$2
  dir=$3
  junk_paths=$4
  [ -z "$junk_paths" ] && junk_paths=false
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
  [ -f "$file_path" ] || abort_verify "$file does not exist!"
  echo "- Extract $file -> $file_path" >&1

  unzip $opts "$zip" "$file.sha256" -d "$VERIFY_DIR" >&2
  [ -f "$hash_path" ] || abort_verify "$file.sha256 does not exist!"

  expected_hash="$(cat "$hash_path")"
  calculated_hash="$(sha256sum "$file_path" | cut -d ' ' -f1)"

  if [ "$expected_hash" == "$calculated_hash" ]; then
    echo "- Verified $file" >&1
  else
    abort_verify "Failed to verify $file"
  fi
}

set_module_files_perm(){
  echo "- Setting permissions"
  set_perm_recursive "$MODPATH" 0 0 0755 0644
}
