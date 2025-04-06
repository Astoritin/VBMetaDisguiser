[English](README.md) | 简体中文

# VBMeta 伪装者 / VBMeta Disguiser

一个用于伪装 VBMeta 属性、系统安全补丁日期和加密状态的 Magisk 模块
/ A Magisk module to disguise the props of vbmeta, security patch date and encryption status

## 支持的 Root 方案

[Magisk](https://github.com/topjohnwu/Magisk) | [KernelSU](https://github.com/tiann/KernelSU) | [APatch](https://github.com/bmax121/APatch)

## 详细信息

该模块的目的之一只是为了过某两个检测器的某一项……哈哈。
~~不过也说不准会有特定的软件也会根据这一点判断是不是已经解锁的设备。~~

1. 请在 密钥验证 / Native Detector 中获取 Boot Hash 并将其保存到 `/data/adb/vbmetadisguiser/vbmeta.conf` 。
2. 默认情况下，AVB 版本会被设定为 `2.0`，而 VBMeta 分区的大小值会被设定为 `4096`，加密状态会被设定为 `encrypted`。
3. 你可以自行在 `/data/adb/vbmetadisguiser/vbmeta.conf` 设定 AVB 的版本号、ROM的 VBMeta 分区的大小和加密状态 (`encrypted`、`unencrypted` 或 `unsupported`)。
4. 你可以自行在 `/data/adb/tricky_store/security_patch.txt` 设定安全补丁日期、system 分区补丁日期和 vendor (供应商)补丁日期。
5. 从v1.2.6开始，你也可以在 `/data/adb/vbmetadisguiser/vbmeta.conf` 中设定想要伪装的安全补丁日期。
- 注意：[TrickyStore](https://github.com/5ec1cff/TrickyStore)的配置 (`/data/adb/tricky_store/security_patch.txt`) 优先级最高，其次才是VBMeta Disguiser的 (`/data/adb/vbmetadisguiser/vbmeta.conf`) 内置的配置

### 注意

- 在 `/data/adb/vbmetadisguiser/vbmeta.conf` 中只需保存键值对的形式 (即键名=键值)，不支持其它注解。
- VBMeta Disguiser 仅负责伪装属性值，若需要伪装 TEE 的结果，请安装模块 [Tricky Store](https://github.com/5ec1cff/TrickyStore) 并参阅其说明。
