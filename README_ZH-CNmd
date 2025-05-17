[English](README.md) | 简体中文

# VBMeta 伪装者 / VBMeta Disguiser

一个用于伪装 VBMeta 属性、系统安全补丁日期和加密状态的 Magisk 模块
/ A Magisk module to disguise the props of vbmeta, security patch date and encryption status

## 支持的 Root 方案

[Magisk](https://github.com/topjohnwu/Magisk) | [KernelSU](https://github.com/tiann/KernelSU) | [APatch](https://github.com/bmax121/APatch)

## 步骤

该模块的目的之一只是为了过某两个检测器的某一项……哈哈。
> 不过也说不准会有特定的软件也会根据这一点判断是不是已经解锁的设备，谁知道呢。

1. 请在 密钥验证 / Native Detector 中获取 Boot Hash
> Native Detector 和某个fork版本的密钥验证APP是支持单击复制 boot hash的。
2. 打开目录 `/data/adb/vbmetadisguiser`，并使用拥有Root权限的文件管理器打开 `vbmeta.conf`。
3. 将 boot 哈希值保存在键值对 `boot_hash=` 后。
4. 若你是第一次使用该模块，请重启。否则请等候一分钟，属性值会被自动更新。

## 配置文件

1. **`avb_version`**: Android Verified Boot (AVB) 版本，是一种用于确保 Android 设备启动时加载未经篡改的操作系统映像的安全机制。
> 默认情况下，AVB 版本会被设定为 `2.0`。
2. **`vbmeta_size`**: Android Verified Boot (AVB) 机制的重要组成部分，用于存储验证启动所需的数据，其大小在不同设备和配置下有所不同。
> 默认情况下，VBMeta 分区的大小值会被设定为 `4096` (4KB)
3. **`crypto_state`**: Data 分区的加密状态。
> 加密状态默认情况下不会被设置。若有需求，你可以手动设置该选项为 `encrypted` 以伪装设备已被加密。(支持 `encrypted` 已加密,`unencrypted` 未加密或 `unsupported`不支持加密)
4. **`all=`、`system=`、`boot=`、`vendor=`**: all 表示所有分区都使用同一个值，system表示系统分区的补丁日期，boot表示boot分区的补丁日期，vendor表示供应商分区补丁日期。
5. 从v1.2.6开始，你也可以在 `/data/adb/vbmetadisguiser/vbmeta.conf` 中设定想要伪装的安全补丁日期。
- 注意：[TrickyStore](https://github.com/5ec1cff/TrickyStore)的配置 (`/data/adb/tricky_store/security_patch.txt`) 优先级最高，其次才是VBMeta Disguiser的 (`/data/adb/vbmetadisguiser/vbmeta.conf`) 内置的配置

## 日志
日志被保存在 `/data/adb/vbmetadisguiser/logs`，你可以查看它并在反馈遇到的问题时提交该日志。

**反馈问题时，请直接打包整个logs文件夹后上传。**

### 注意

1. 推荐在 `/data/adb/vbmetadisguiser/vbmeta.conf` 中仅保存键值对的形式 (即键名=键值)。虽然不推荐，你可以用 # 号进行注释。
2. VBMeta Disguiser 仅负责伪装属性值，TEE 返回的结果并不在 VBMeta Disguiser 的功能范畴。若需要伪装 TEE 返回的结果，请安装模块 [Tricky Store](https://github.com/5ec1cff/TrickyStore) 并参照其说明进行操作。
