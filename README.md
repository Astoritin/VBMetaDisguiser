English | [简体中文](README_ZH-CN.md)

# VBMeta Disguiser / VBMeta 伪装者

A Magisk module to disguise the props of vbmeta, security patch date and encryption status / 一个用于伪装 VBMeta 属性、系统安全补丁日期和加密状态的 Magisk 模块

## Supported Root Solution

[Magisk](https://github.com/topjohnwu/Magisk) | [KernelSU](https://github.com/tiann/KernelSU) | [APatch](https://github.com/bmax121/APatch)

## Steps

One of the purpose of writing this module is bypass the specific items in specific detectors...lol.
> Who knows? Maybe specific APPs might also use this point to check out whether the device has unlocked bootloader.

1. Please get the Boot Hash in **Key Attestation/Native Detector**.
> Native detector and one fork of Key Attestation supports clicking on and copy the boot hash.
2. Open `/data/adb/vbmetadisguiser` and open `vbmeta.conf` with root permission file explorer.
3. Save the boot hash behind the keypair `boot_hash=` with the copy one.
4. Reboot if it is the first time you use this module. If not, just wait a minute. It will update properties automatically.

## Configuration File

1. **`avb_version`**: Android Verified Boot (AVB) version, a security mechanism designed to ensure that an Android device boots an unmodified operating system image.
> AVB version will be set as `2.0` by default.
2. **`vbmeta_size`**: A crucial component of the Android Verified Boot (AVB) mechanism, storing data necessary for verified booting. Its size varies depending on the device and configuration.
> The size of VBMeta partition will be set as `4096` by default.
3. **`crypto_state`**: the encryption state of Data partition.
> The encryption status will NOT be set by default. If needed, you can set this option as `encrypted` to pretend your device has been encrypted. (Support `encrypted`,`unencrypted` or `unsupported`)
4. **`all=`、`system=`、`boot=`、`vendor=`**: all means all the partitions use the same value, as system means system partition security patch, so are boot and vendor.
5. Since v1.2.6, you can configure security patch date in `/data/adb/vbmetadisguiser/vbmeta.conf` too.
- NOTICE: TrickyStore's configuration (`/data/adb/tricky_store/security_patch.txt`) has the highest priority, with VBMeta Disguiser's built-in configuration (`/data/adb/vbmetadisguiser/vbmeta.conf`) coming second

## Logs
Logs are saved in `/data/adb/bloatwareslayer/logs`, you can review them and submit them when reporting issues. 

**When reporting issues, please simply zip the entire logs folder and upload it.**

### NOTICE

1. Save the form of keypair ONLY (key=value) in `/data/adb/vbmetadisguiser/vbmeta.conf` is recommended. You can keep comments with symbol # too, even though it is not recommended.
2. VBMeta Disguiser will disguise these properties ONLY, the result of TEE is not within VBMeta Disguiser's duty. You may install [Tricky Store](https://github.com/5ec1cff/TrickyStore) and follow the instructions if you want to disguise the result from TEE.
