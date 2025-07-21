English | [简体中文](README_ZH-CN.md)

# VBMeta Disguiser
A Magisk module to disguise the properties of vbmeta

## Supported Root Solution
[Magisk](https://github.com/topjohnwu/Magisk) | [KernelSU](https://github.com/tiann/KernelSU) | [APatch](https://github.com/bmax121/APatch)

## Why does this module exist?
One of the purpose of writing this module is bypass the specific items in specific detectors...lol.
> Who knows? Maybe specific APPs might also use this point to check out whether the device has unlocked bootloader.  

**The core reason is I don't want to do something with flashing so many modules. Therefore, I wrote this module with so many weird features.**  
  
**NOTICE: This module will only modify properties, as for the result of TEE/system API, please look for other modules**

## Steps
1. Please get the Boot Hash in **Key Attestation/Native Detector**.
> Native detector and one fork of Key Attestation supports clicking on and copying the boot hash.
2. Open `/data/adb/vbmetadisguiser` and open `vbmeta.conf` with root permission file explorer.
3. Save the boot hash behind the keypair `boot_hash=` with the copy one and reboot your device.

## Configuration File
1. **`avb_version`**: Android Verified Boot (AVB) version, a security mechanism designed to ensure that an Android device boots an unmodified operating system image.
> AVB version will be set as `2.0` by default.
2. **`vbmeta_size`**: A crucial component of the Android Verified Boot (AVB) mechanism, storing data necessary for verified booting. Its size varies depending on the device and configuration.
> The size of VBMeta partition will be set as `4096` by default.
3. **`crypto_state`**: the encryption state of Data partition.
> The encryption status will NOT be set by default. If needed, you can set this option as `encrypted` to pretend your device has been encrypted. (Support `encrypted`,`unencrypted` or `unsupported`)
4. **`all=`、`system=`、`boot=`、`vendor=`**: all means all the partitions use the same value, as system means system partition security patch, so are boot and vendor.
5. **`props_slay`**: remove ordered properties, it is set as `false` by default.
6. **`props_list`**: a system properties list to remove system properties forever.
> supports multi-line, one per line, please enclose the items in double quotation marks. For example: `props_list="persist.a persist.b persist.c"`
- To apply properties removal, you need to reboot your device once or twice.
> This is NOT a bug. According to how resetprop works, you have to do it. You may see item `Property Modified (10)` in detector Native Test if only reboot once.
- These properties will be back (restored) as setting `props_slay=false` and finishing reboot or uninstalling VBMeta Disguiser in normal way
- NOTICE: properties backup file are located in `/data/adb/vbmetadisguiser/slain_prop.prop`, please do NOT remove it casually
> WARN: if you remove it, these properties will be lost forever, which means you can only unroot and root again to restore properties
7. **`install_recovery_slay`**: Delete install-recovery.sh (Systemlessly), disabled by default
8. Since v1.2.6, you can configure security patch date in `/data/adb/vbmetadisguiser/vbmeta.conf` too.
- NOTICE: TrickyStore's configuration (`/data/adb/tricky_store/security_patch.txt`) has the highest priority, with VBMeta Disguiser's built-in configuration (`/data/adb/vbmetadisguiser/vbmeta.conf`) coming second. In order to avoid unnecessary interact, the value of VBMeta Disguiser config file (`/data/adb/vbmetadisguiser/vbmeta.conf`) related to security patch date properties will be ignored once detecting TrickyStore config file (`/data/adb/tricky_store/security_patch.txt`) exists.

## Logs
Logs are saved in `/data/adb/vbmetadisguiser/logs`, as config file `/data/adb/vbmetadisguiser`.  
**When reporting issues, please simply zip the entire `vbmetadisguiser` folder and upload it.**

### NOTICE
1. Save the form of keypair ONLY (key=value) in `/data/adb/vbmetadisguiser/vbmeta.conf` is recommended. You can keep comments with symbol # too, even though it is not recommended.
2. VBMeta Disguiser will disguise these properties ONLY, the result of TEE or system API is not within VBMeta Disguiser's duty. You may install [Tricky Store](https://github.com/5ec1cff/TrickyStore) and follow the instructions if you want to disguise the result from TEE. Please look for other modules if you want to disguise the result from system API.

## Credits
- [Magisk](https://github.com/topjohnwu/Magisk) - the foundation which makes everything possible
- [LSPosed](https://github.com/LSPosed/LSPosed) - the implementation of function extract and root solution check
- [Zygisk Next](https://github.com/Dr-TSNG/ZygiskNext) - the implementation of function extract and root solution check