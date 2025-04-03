简体中文 | [English](README_EN.md)

# VBMeta 伪装者 / VBMeta Disguiser

一个用于伪装 VBMeta 属性、系统安全补丁日期和加密状态的 Magisk 模块
/ A Magisk module to disguise the props of vbmeta, security patch date and encryption status✨

## 支持的 Root 方案

[Magisk](https://github.com/topjohnwu/Magisk) | [KernelSU](https://github.com/tiann/KernelSU) | [APatch](https://github.com/bmax121/APatch)

## 详细信息

该模块的目的之一只是为了过某两个检测器的某一项……哈哈。
~~不过也说不准会有特定的软件也会根据这一点判断是不是已经解锁的设备。~~

1. 请在 密钥验证 / Native Detector 中获取 Boot Hash 并将其保存到 `/data/adb/vbmetadisguiser/vbmeta.conf` 。
2. 默认情况下，AVB 版本会被设定为 `2.0`，而 VBMeta 分区的大小值会被设定为 `4096`，加密状态会被设定为 `encrypted`。
3. 你可以自行在`/data/adb/vbmetadisguiser/vbmeta.conf`设定 AVB 的版本号、ROM的 VBMeta 分区的大小和加密状态 (`encrypted`、`unencrypted` 或 `unsupported`)。


### 注意

在 `/data/adb/vbmetadisguiser/vbmeta.conf` 中只需保存键值对的形式 (即键名=键值)，不支持其它注解。
在 `/data/adb/tricky_store/security_patch.txt` 中配置安全补丁日期，详情请参考[Tricky Store](https://github.com/5ec1cff/TrickyStore)的说明。
