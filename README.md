# VBMeta 伪装者 / VBMeta Disguiser

一个用于伪装 VBMeta 属性的 Magisk 模块
/ A Magisk module to disguise VBMeta props

<details>
<summary>注意 / NOTICE</summary>
该 Magisk 模块仅能在已解锁 Bootloader 的设备上使用，并且需要特定的 Root 模块管理器 (Magisk、KernelSU、APatch)。
如果你没有 Root 甚至没有解锁 Bootloader，那么该 Magisk 模块无法在你的设备上工作。
This Magisk required devices with unlocked BootLoader and specific Root Modules Manager (Magisk/KernelSU/APatch).
This Magisk module WILL NOT be able to work if your device doesn't get root access or even unlock BootLoader.
</details>

## 支持的 Root 方案 / Support Root Solution

- [Magisk](https://github.com/topjohnwu/Magisk)
- [KernelSU](https://github.com/tiann/KernelSU)
- [APatch](https://github.com/bmax121/APatch)

## 详细信息 / Details

该模块的目的之一只是为了过某两个检测器的某一项……哈哈。 / One of the purpose of writing this module is bypass the specific items in specific detectors...lol.

请在 密钥验证 / Native Detector 中获取 Boot Hash 并将其保存到`/data/adb/vbmetadisguiser/vbmeta.conf`。
Please obtain the Boot Hash in **Key Attestation/Native Detector** and save it to the file `/data/adb/vbmetadisguiser/vbmeta.conf`.
默认情况下，AVB 版本会被设定为 `2.0`，而 VBMeta 分区的大小值会被设定为 `4096`，你可以自行在`/data/adb/vbmetadisguiser/vbmeta.conf`设定 AVB 的版本号。
AVB version will be set as `2.0` by default, the size of VBMeta partition will be set as `4096` by default, you can set it in `/data/adb/vbmetadisguiser/vbmeta.conf`.


<details open>
<summary>注意 / NOTICE</summary>
在 `/data/adb/vbmetadisguiser/vbmeta.conf` 中只需保存键值对的形式 (即键名=键值)，不支持其它注解。
Save the form of keypair ONLY (key=value) in `/data/adb/vbmetadisguiser/vbmeta.conf`, any additional comments or annotations is not supported.
</details>
