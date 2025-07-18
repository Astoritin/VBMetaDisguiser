#!/system/bin/sh
MODDIR=${0%/*}

CONFIG_DIR="/data/adb/vbmetadisguiser"
CONFIG_FILE="$CONFIG_DIR/vbmeta.conf"

MOD_INTRO="Disguise VBMeta properties."
MODULE_PROP="$MODDIR/module.prop"
SEPARATE_LINE="----------------------------------------"

FROM_ACTION=true

ROOT_FILE_MANAGERS="
com.speedsoftware.rootexplorer/com.speedsoftware.rootexplorer.RootExplorer
com.mixplorer/com.mixplorer.activities.BrowseActivity
bin.mt.plus/.Main
bin.mt.plus/bin.mt.plus.Main
com.lonelycatgames.Xplore/com.lonelycatgames.Xplore.Browser
com.ghisler.android.TotalCommander/com.ghisler.android.TotalCommander.MainActivity
pl.solidexplorer2/pl.solidexplorer.activities.MainActivity
com.amaze.filemanager/com.amaze.filemanager.activities.MainActivity
io.github.muntashirakon.AppManager/io.github.muntashirakon.AppManager.fm.FmActivity
io.github.muntashirakon.AppManager.debug/io.github.muntashirakon.AppManager.fm.FmActivity
nextapp.fx/nextapp.fx.ui.ExplorerActivity
me.zhanghai.android.files/me.zhanghai.android.files.filelist.FileListActivity
"

echo "$SEPARATE_LINE"
echo "- VBMeta Disguiser"
echo "- By Astoritin Ambrosius"
echo "$SEPARATE_LINE"
echo "- $MOD_INTRO"
echo "$SEPARATE_LINE"
echo "- Opening config dir"
echo "- and update VBMeta Properties manually"
echo "$SEPARATE_LINE"
echo "- If nothing happened after case closed"
echo "- that means not any available root"
echo "- file explorer is found on your device"
echo "- Anyway, you can open config dir manually"
echo "$SEPARATE_LINE"
sleep 1

IFS=$'\n'

for fm in $ROOT_FILE_MANAGERS; do

    PKG=${fm%/*}

    if pm path "$PKG" >/dev/null 2>&1; then
        echo "> Launching $PKG"
        am start -n "$fm" "file://$CONFIG_DIR"
        result_action="$?"
        echo "- am start -n $fm file://$CONFIG_DIR ($result_action)"
        if [ $result_action -eq 0 ]; then
            echo "$SEPARATE_LINE"
            echo "- Case closed!"
            sleep 1
            . "$MODDIR/service.sh"
            return 0
        fi
    else
        echo "- $PKG is NOT installed"
    fi
done

echo "$SEPARATE_LINE"
echo "- Case closed!"
