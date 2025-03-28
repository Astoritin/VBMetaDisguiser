# VBMeta 伪装者 / VBMeta Disguiser

一个用于伪装 VBMeta 属性和加密属性的 Magisk 模块
/ A Magisk module to disguise VBMeta props and the encryption status

<details>
<summary>注意 / NOTICE</summary>
该 Magisk 模块仅能在已解锁 Bootloader 的设备上使用，并且需要特定的 Root 模块管理器 (Magisk、KernelSU、APatch)。
如果你没有 Root 甚至没有解锁 Bootloader，那么该 Magisk 模块无法在你的设备上工作。<br>
This Magisk module required devices with unlocked BootLoader and specific Root Modules Manager (Magisk/KernelSU/APatch).
This Magisk module WILL NOT be able to work if your device doesn't get root access or even unlock BootLoader.
</details>

## 支持的 Root 方案 / Support Root Solution

- [Magisk](https://github.com/topjohnwu/Magisk)
- [KernelSU](https://github.com/tiann/KernelSU)
- [APatch](https://github.com/bmax121/APatch)

## 详细信息 / Details

该模块的目的之一只是为了过某两个检测器的某一项……哈哈。<br>
<del>不过也说不准会有特定的软件也会根据这一点判断是不是已经解锁的设备。</del><br>
One of the purpose of writing this module is bypass the specific items in specific detectors...lol.<br>
<del>Some specific APPs might also use this point to check out whether the device has unlocked bootloader.</del><br><br>
请在 密钥验证 / Native Detector 中获取 Boot Hash 并将其保存到 `/data/adb/vbmetadisguiser/vbmeta.conf` 。<br>
Please obtain the Boot Hash in **Key Attestation/Native Detector** and save it to the file `/data/adb/vbmetadisguiser/vbmeta.conf`. <br><br>
默认情况下，AVB 版本会被设定为 `2.0`，而 VBMeta 分区的大小值会被设定为 `4096`，加密状态会被设定为 `encrypted`。<br>
你可以自行在`/data/adb/vbmetadisguiser/vbmeta.conf`设定 AVB 的版本号、ROM的 vbmeta 分区的大小和加密状态为 `unencrypted` 或 `unsupported`。<br>
About these props: AVB version will be set as `2.0` by default, the size of VBMeta partition will be set as `4096` by default, the encryption status will be set as `encrypted` by default.<br>
You can set the details in `/data/adb/vbmetadisguiser/vbmeta.conf` included AVB version, the size of VBMeta partition and the encryption status (`encrypted`,`unencrypted` or `unsupported`)<br>

<details open>
<summary>注意 / NOTICE</summary>
在 <code>/data/adb/vbmetadisguiser/vbmeta.conf</code> 中只需保存键值对的形式 (即键名=键值)，不支持其它注解。<br><br>
Save the form of keypair ONLY (key=value) in <code>/data/adb/vbmetadisguiser/vbmeta.conf</code>, any additional comments or annotations is not supported.
</details>
