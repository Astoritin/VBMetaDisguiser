## VBMeta 伪装者 / VBMeta Disguiser

一个用于伪装 VBMeta 属性、加密状态、系统安全补丁日期和删除特定属性值的 Magisk 模块
/ A Magisk module to disguise the props of vbmeta, encryption status, encryption status and remove specific properties

### 1.3.5

- Fixed an issue which caused Properties Slayer ignoring certain ROMs' behavior adding properties after boot completed
> Thanks a lot for iabeefe reporting this [issue](https://github.com/Astoritin/VBMetaDisguiser/issues/2)
- To apply properties removal, you need to reboot your device once or twice.
> This is NOT a bug. According to how resetprop works, you have to do it. You may see item `Property Modified (10)` in detector Native Test if only reboot once.
- Add feature back: install-recovery.sh Slayer, supports removing file install-recovery.sh systemlessly, disabled by default
> You can set `install_recovery_slay=true` to enable this feature in config file `/data/adb/vbmetadisguiser/vbmeta.conf`
- Add feature back: addon.d Slayer, supports removing directory addon.d systemlessly, disabled by default
> You can set `addon_d_slay=true` to enable this feature in config file `/data/adb/vbmetadisguiser/vbmeta.conf`
- Support updating VBmeta partition properties, data partition properties and removing ordered properties automatically
- Remove large amount of useless codes to reduce module file size

- 修复了一个问题，该问题曾导致 Properties Slayer 疏忽了某些ROM启动完成时才添加属性值（props）的行为
> 多谢 iabeefe 报告该[问题](https://github.com/Astoritin/VBMetaDisguiser/issues/2)
- 为了让属性值移除生效，你需要重启你的设备一到两次
> 这不是bug，是根据 resetprop 移除属性值的机制不得不这么做，只重启一次你可能会在 Native Test 中看到项目 `Property Modified (10)`
- 重新添加该功能：干掉 install-recovery.sh，支持不修改系统分区的情况下移除文件 install-recovery.sh，默认禁用
> 你可以在 `/data/adb/vbmetadisguiser/vbmeta.conf` 中设定 `install_recovery_slay=true` 以启用该功能
- 重新添加该功能：干掉 addon.d，支持不修改系统分区的情况下移除目录 addon.d，默认禁用
> 你可以在 `/data/adb/vbmetadisguiser/vbmeta.conf` 中设定 `addon_d_slay=true` 以启用该功能
- 支持实时更新 VBMeta 分区属性值、Data分区属性值和移除指定属性值。
- 移除大量无用代码以减小文件体积
