English | [简体中文](README_ZH-SC.md)

# VBMeta Disguiser / VBMeta 伪装者

A Magisk module to disguise the props of vbmeta, security patch date and encryption status / 一个用于伪装 VBMeta 属性、系统安全补丁日期和加密状态的 Magisk 模块

## Supported Root Solution

[Magisk](https://github.com/topjohnwu/Magisk) | [KernelSU](https://github.com/tiann/KernelSU) | [APatch](https://github.com/bmax121/APatch)

## Details

One of the purpose of writing this module is bypass the specific items in specific detectors...lol.
~~Some specific APPs might also use this point to check out whether the device has unlocked bootloader.~~

1. Please obtain the Boot Hash in **Key Attestation/Native Detector** and save it to the file `/data/adb/vbmetadisguiser/vbmeta.conf`.
2. About these props: AVB version will be set as `2.0` by default, the size of VBMeta partition will be set as `4096` by default, the encryption status will be set as `encrypted` by default.
3. You can set the details in `/data/adb/vbmetadisguiser/vbmeta.conf` included AVB version, the size of VBMeta partition and the encryption status (`encrypted`,`unencrypted` or `unsupported`).
4. You can set the details in `/data/adb/tricky_store/security_patch.txt` included security patch date, system partition patch date and vendor partition patch date.
5. Since v1.2.6, you can configure security patch date in `/data/adb/vbmetadisguiser/vbmeta.conf` too.
- NOTICE: TrickyStore's configuration (`/data/adb/tricky_store/security_patch.txt`) has the highest priority, with VBMeta Disguiser's built-in configuration (`/data/adb/vbmetadisguiser/vbmeta.conf`) coming second

### NOTICE

- Save the form of keypair ONLY (key=value) in `/data/adb/vbmetadisguiser/vbmeta.conf`, any additional comments or annotations is not supported.
- VBMeta Disguiser will disguise these properties ONLY, you may install [Tricky Store](https://github.com/5ec1cff/TrickyStore) and read the instructions if you want to disguise the result from TEE.
