[English](README.md) | 简体中文

# VBMeta 伪装者
一个用于伪装 VBMeta 属性的 Magisk 模块

## 支持的 Root 方案  
[Magisk](https://github.com/topjohnwu/Magisk) | [KernelSU](https://github.com/tiann/KernelSU) | [APatch](https://github.com/bmax121/APatch)

## 为什么存在这个模块？  
该模块的目的之一只是为了过某两个检测器的某一项……哈哈。
> 不过也说不准会有特定的软件也会根据这一点判断是不是已经解锁的设备，谁知道呢。  

**主要原因是因为有些事情不想写多个模块去做，索性写了这么个有着各种奇怪功能的模块。**  
  
**注意: 该模块只修改属性值，对于TEE/系统API返回的结果，请寻找其他模块**

## 步骤
1. 请在 密钥验证 / Native Detector 中获取 Boot Hash
> Native Detector 和某个fork版本的密钥验证APP是支持单击复制 boot hash的。
2. 打开目录 `/data/adb/vbmeta_disguiser`，并使用拥有Root权限的文件管理器打开 `vbmeta.conf`。
3. 将 boot 哈希值保存在键值对 `boot_hash=` 后重新启动你的设备。

## 配置文件
1. **`avb_version`**: Android Verified Boot (AVB) 版本，是一种用于确保 Android 设备启动时加载未经篡改的操作系统映像的安全机制。
> 默认情况下，AVB 版本会被设定为 `2.0`。
2. **`vbmeta_size`**: Android Verified Boot (AVB) 机制的重要组成部分，用于存储验证启动所需的数据，其大小在不同设备和配置下有所不同。
> 默认情况下，VBMeta 分区的大小值会被设定为 `4096` (4KB)
3. **`crypto_state`**: Data 分区的加密状态。
> 加密状态默认情况下不会被设置。若有需求，你可以手动设置该选项为 `encrypted` 以伪装设备已被加密。(支持 `encrypted` 已加密,`unencrypted` 未加密或 `unsupported`不支持加密)
4. **`props_slay`**: 移除指定的属性值，默认值为`false`(禁用)。
5. **`props_list`**: 一个用于永久移除系统属性值的系统属性清单。
> 支持多行，一行一个，请将这些项目用双引号括起来。例如：`props_list="persist.a persist.b persist.c"`
- 为了让属性值移除生效，你需要重启你的设备一到两次
> 这不是bug，是根据 resetprop 移除属性值的机制不得不这么做，只重启一次你可能会在 Native Test 中看到项目 `Property Modified (10)`
- 这些属性值会在设定 `props_slay=false` 并完成一次重启，或正常卸载 VBMeta Disguiser 时被还原
- 注意：属性值备份文件位于 `/data/adb/vbmeta_disguiser/slain_prop.prop`，请勿随意删除
> 警告: 若你移除该文件，这些属性值将永久丢失
6. **`install_recovery_slay`**：移除 install-recovery.sh 文件 (不修改系统)，默认禁用
7. **`security_patch_disguise`**: 伪装安全补丁日期。该功能算是对模块 [Tricky Store](https://github.com/5ec1cff/TrickyStore) 的补充。由于 TrickyStore 仅伪装 TEE 返回的结果，VBMeta Disguiser 会伪装相应属性值，该功能默认禁用。推荐在 TrickyStore 的配置文件 (`/data/adb/tricky_store/security_patch.txt`) 中设置。你也可以在 `/data/adb/vbmeta_disguiser/vbmeta.conf` 内配置安全补丁日期，但正如我所说，仅属性值会被伪装，若 APP 请求 TEE 返回的结果，那么这是徒劳的。
8. **`all=`、`system=`、`boot=`、`vendor=`**: all 意味着所有日期共用相同的值。system 是指系统的安全补丁日期，而 boot/vendor 是指 boot/vendor 分区的安全补丁日期。格式与 [Tricky Store](https://github.com/5ec1cff/TrickyStore) 的配置文件相同。
> 例如 all=20250705 (当你设定了all的值，system/boot/vendor 的值会被忽略)  
> system=20230301 (若你没有设置all的值, 则请你手动设置 system, boot 和 vendor 的值)  
> vendor=yes, vendor=no, vendor=20210101, yes 是指与 system 的值相同, no 是指你不需要伪装该值。你也可以手动为 vendor 分区指定新的值  
> boot=yes, boot=no, boot=20210205, 规则与 vendor 分区相同  
- 注意：[TrickyStore](https://github.com/5ec1cff/TrickyStore)的配置文件 (`/data/adb/tricky_store/security_patch.txt`) 优先级最高，其次才是VBMeta Disguiser的配置文件 (`/data/adb/vbmeta_disguiser/vbmeta.conf`)。并且，为了防止不必要的交互，一旦检测到 TrickyStore 的配置文件 (`/data/adb/tricky_store/security_patch.txt`) 存在，VBMeta Disguiser 的配置文件 (`/data/adb/vbmeta_disguiser/vbmeta.conf`) 中有关安全补丁日期的属性值会被忽略。
9. **`bootloader_props_spoof`**: 伪装 bootloader 属性值为锁定，默认禁用
10. **`build_type_spoof`**: 伪装 ROM 的构建类别为 user/release，默认禁用
- 注意：在某些 ROM 中，随意启用该功能将导致系统无法启动！

## 日志
日志被保存在 `/data/adb/vbmeta_disguiser/logs`，配置文件被保存在 `/data/adb/vbmeta_disguiser`。  
  
**反馈问题时，请直接打包整个vbmeta_disguiser文件夹后上传。**

### 注意
1. 推荐在 `/data/adb/vbmeta_disguiser/vbmeta.conf` 中仅保存键值对的形式 (即键名=键值)。虽然不推荐，你可以用 # 号进行注释。
2. VBMeta Disguiser 仅负责伪装属性值，TEE 返回的结果和系统 API 返回的结果并不在 VBMeta Disguiser 的功能范畴。若需要伪装 TEE 返回的结果，请安装模块 [Tricky Store](https://github.com/5ec1cff/TrickyStore) 并参照其说明进行操作，若需要伪装系统 API 返回的结果，请搜寻其他模块。

## 鸣谢
- [Magisk](https://github.com/topjohnwu/Magisk) - 让一切皆有可能的基石
- [LSPosed](https://github.com/LSPosed/LSPosed) - extract和root方案检查函数实现
- [Shamiko](https://github.com/LSPosed/LSPosed.github.io) - Bootloader属性值伪装函数的实现
- [Zygisk Next](https://github.com/Dr-TSNG/ZygiskNext) - extract和root方案检查函数实现