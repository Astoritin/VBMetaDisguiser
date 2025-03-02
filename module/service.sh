#!/system/bin/sh
MODDIR=${0%/*}

CONFIG_DIR=/data/adb/boothashdisguiser
HASH_INFO="$CONFIG_DIR/hash.info"
LOG_DIR="$CONFIG_DIR/logs"
BHD_LOG_FILE="$LOG_DIR/log.txt"
MOD_NAME="$(sed -n 's/^name=\(.*\)/\1/p' "${MODDIR}/module.prop")"
MOD_AUTHOR="$(sed -n 's/^author=\(.*\)/\1/p' "${MODDIR}/module.prop")"
MOD_VER="$(sed -n 's/^version=\(.*\)/\1/p' "${MODDIR}/module.prop") ($(sed -n 's/^versionCode=\(.*\)/\1/p' "${MODDIR}/module.prop"))"

mkdir -p "$LOG_DIR"

{
    echo "--Magisk Module Info----------------------------------------------------------------------------------"
    echo "- $MOD_NAME"
    echo "- By $MOD_AUTHOR"
    echo "- Version: $MOD_VER"
    echo "- Current time stamp: $(date +"%Y-%m-%d %H:%M:%S")"
    echo "- Starting service.sh..."
    echo "--env Info--------------------------------------------------------------------------------------------"
    env | sed 's/^/- /'
    echo "--start service---------------------------------------------------------------------------------------"
} > "$BHD_LOG_FILE"

(
    while [ "$(getprop sys.boot_completed)" != "1" ]; do
        sleep 1
    done

    if [ -s "$HASH_INFO" ]; then
        HASH_INFO_SER=$(cat "$HASH_INFO")
        echo "- Detect boot hash: $HASH_INFO_SER"
        resetprop "ro.boot.vbmeta.digest" "$HASH_INFO_SER"
        echo "- Done!"
    elif [ ! -f "$HASH_INFO" ]; then
        echo "- hash.info does not exist!"
    else
        echo "- File exist but unreadable!"
    fi

    echo "- service.sh case closed!"
    echo "------------------------------------------------------------------------------------------------------"
 ) >> $BHD_LOG_FILE &
