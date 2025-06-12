## VBMeta 伪装者 / VBMeta Disguiser

一个用于伪装 VBMeta 属性、加密状态、系统安全补丁日期和删除特定属性值的 Magisk 模块
/ A Magisk module to disguise the props of vbmeta, encryption status, encryption status and remove specific properties

### 1.3.3

- Add new feature: Properties Slayer
- New config in `vbmeta.conf`: `props_slay=false`, which means this feature is disabled as default
- New config in `vbmeta.conf`: `props_list=`, which means the properties you want VBMeta Disguiser to remove
> For example: Set `props_slay=true` to enable Properties Slayer
> `props_list=persist.sys.spoof.gms` means delete `persist.sys.spoof.gms` from system properties list forever
> `props_list` supports multi-line, one per line, please enclose the item in double quotation marks
- These properties will be back (restored) as setting `props_slay=false` and finishing reboot or uninstalling VBMeta Disguiser in normal way
- NOTICE: properties backup file are located in `/data/adb/vbmetadisguiser/logs/slain_prop.prop`, please do NOT remove it casually
> WARN: if you remove it, these properties will be lost forever, which means you can only unroot and root again to restore properties
- Sync the changes of aa-util.sh in Bloatware Slayer

- 添加新功能：删除props属性值
- `vbmeta.conf` 中的新配置: `props_slay=false`，代表着该功能默认被禁用
- `vbmeta.conf` 中的新配置: `props_list=`, 代表着你需要 VBMeta Disguiser 移除的属性值
> 举个例子：设置 `props_slay=true` 以启用属性值移除功能
> `props_list=persist.sys.spoof.gms` 即从系统属性值清单中永远删除属性值 `persist.sys.spoof.gms` 
> `props_list` 支持多行，一行一个，请用双引号将这些条目括起来
- 这些属性值会在设定 `props_slay=false` 并完成一次重启，或正常卸载 VBMeta Disguiser 时被还原
- 注意：属性值备份文件位于 `/data/adb/vbmetadisguiser/logs/slain_prop.prop`，请勿随意删除
> 警告: 若你移除该文件，这些属性值将永久丢失，可能只有取消root并重新root才能还原这些属性值
- 同步 Bloatware Slayer 的 aa-util.sh 中的变动
