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
2. 打开目录 `/data/adb/vbmetadisguiser`，并使用拥有Root权限的文件管理器打开 `vbmeta.conf`。
3. 将 boot 哈希值保存在键值对 `boot_hash=` 后重新启动你的设备。

## 配置文件
1. **`avb_version`**: Android Verified Boot (AVB) 版本，是一种用于确保 Android 设备启动时加载未经篡改的操作系统映像的安全机制。
> 默认情况下，AVB 版本会被设定为 `2.0`。
2. **`vbmeta_size`**: Android Verified Boot (AVB) 机制的重要组成部分，用于存储验证启动所需的数据，其大小在不同设备和配置下有所不同。
> 默认情况下，VBMeta 分区的大小值会被设定为 `4096` (4KB)
3. **`crypto_state`**: Data 分区的加密状态。
> 加密状态默认情况下不会被设置。若有需求，你可以手动设置该选项为 `encrypted` 以伪装设备已被加密。(支持 `encrypted` 已加密,`unencrypted` 未加密或 `unsupported`不支持加密)
4. **`all=`、`system=`、`boot=`、`vendor=`**: all 表示所有分区都使用同一个值，system表示系统分区的补丁日期，boot表示boot分区的补丁日期，vendor表示供应商分区补丁日期。
5. **`props_slay`**: 移除指定的属性值，默认值为`false`(禁用)。
6. **`props_list`**: 一个用于永久移除系统属性值的系统属性清单。
> 支持多行，一行一个，请将这些项目用双引号括起来。例如：`props_list="persist.a persist.b persist.c"`
- 为了让属性值移除生效，你需要重启你的设备一到两次
> 这不是bug，是根据 resetprop 移除属性值的机制不得不这么做，只重启一次你可能会在 Native Test 中看到项目 `Property Modified (10)`
- 这些属性值会在设定 `props_slay=false` 并完成一次重启，或正常卸载 VBMeta Disguiser 时被还原
- 注意：属性值备份文件位于 `/data/adb/vbmetadisguiser/slain_prop.prop`，请勿随意删除
> 警告: 若你移除该文件，这些属性值将永久丢失，可能只有取消root并重新root才能还原这些属性值
7. **`install_recovery_slay`**：移除 install-recovery.sh 文件 (不修改系统)，默认禁用
8. 从v1.2.6开始，你也可以在 `/data/adb/vbmetadisguiser/vbmeta.conf` 中设定想要伪装的安全补丁日期。
- 注意：[TrickyStore](https://github.com/5ec1cff/TrickyStore)的配置文件 (`/data/adb/tricky_store/security_patch.txt`) 优先级最高，其次才是VBMeta Disguiser的配置文件 (`/data/adb/vbmetadisguiser/vbmeta.conf`)。并且，为了防止不必要的交互，一旦检测到 TrickyStore 的配置文件 (`/data/adb/tricky_store/security_patch.txt`) 存在，VBMeta Disguiser 的配置文件 (`/data/adb/vbmetadisguiser/vbmeta.conf`) 中有关安全补丁日期的属性值会被忽略。

## 日志
日志被保存在 `/data/adb/vbmetadisguiser/logs`，配置文件被保存在 `/data/adb/vbmetadisguiser`。  
**反馈问题时，请直接打包整个vbmetadisguiser文件夹后上传。**

### 注意
1. 推荐在 `/data/adb/vbmetadisguiser/vbmeta.conf` 中仅保存键值对的形式 (即键名=键值)。虽然不推荐，你可以用 # 号进行注释。
2. VBMeta Disguiser 仅负责伪装属性值，TEE 返回的结果和系统 API 返回的结果并不在 VBMeta Disguiser 的功能范畴。若需要伪装 TEE 返回的结果，请安装模块 [Tricky Store](https://github.com/5ec1cff/TrickyStore) 并参照其说明进行操作，若需要伪装系统 API 返回的结果，请搜寻其他模块。

## 鸣谢
- [Magisk](https://github.com/topjohnwu/Magisk) - 让一切皆有可能的基石
- [LSPosed](https://github.com/LSPosed/LSPosed) - extract和root方案检查函数实现
- [Zygisk Next](https://github.com/Dr-TSNG/ZygiskNext) - extract和root方案检查函数实现