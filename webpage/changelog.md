## VBMeta 伪装者 / VBMeta Disguiser

一个用于伪装 VBMeta 属性、加密状态和系统安全补丁日期的 Magisk 模块
/ A Magisk module to disguise the props of vbmeta, encryption status and security patch date

### 1.2.9

- Remove the restrictions of the length property VBMeta hash
- 移除属性 VBMeta 哈希值的长度限制
- Fix some logical problems
- 修复部分逻辑问题
- Add soft bootloader status spoof for users not using Shamiko or Sensitive Props
- 为不使用 Shamiko 或者 Sensitive Props 增加弱 bootloader 状态伪装功能

### 1.2.8

- Fix some logical loophole
- 修复部分逻辑漏洞
- Sync the changes of aautilities.sh in Bloatware Slayer
- 同步 Bloatware Slayer 的 aautilities.sh 中的变动
- update module description
- 更新模块描述
- SHA256: `07caba7b74c51b77c0c03862d16460a58095c9d98183c7f7f5672684f04ffe1b`

### 1.2.7

- Add new feature: custom `install-recovery.sh` script hiding/removing
- 新增功能：隐藏/删除自定义的 `install-recovery.sh` 脚本
- Add new feature: custom `addon.d` folder hiding/removing
- 新增功能：隐藏/删除自定义的 `addon.d` 文件夹
- These features are disabled by default, support three mode: `MN` (Make Node), `RN` (Rename), `ED` (Erase/Delete) 
- 这些功能默认情况下禁用，支持以下三种模式：`MN` (Make Node，创建节点模式)，`RN` (Rename，重命名)，`ED` (抹除/删除)
- WARN: `MN` (Make Node) mode requires Magisk 28102+, KernelSU or APatch, `RN` (Rename) and `ED` (Erase/Delete) are NOT systemless ways, if your ROM is EROFS or read-only it won't work at all, before it works you need to know how to rescue from being brick if you use. Once you change the working mode manually means you have got these warning, I have nothing to do if your device gets bootloop or brick
- 警告：`MN` (Make Node，创建节点模式) 要求 Magisk 28102+、KernelSU 或 APatch，`RN` (重命名模式) 和 `ED` (抹除/删除模式) 涉及直接修改系统分区，若你的ROM是EROFS或者只读，则这两种模式无法工作。若你需要切换至这两种模式，你需要在这两种模式生效前知道如何救砖！一旦你手工更改到这两种工作模式意味着你已经收到了上述警告，若你的设备卡在启动界面或者变砖，则与我无关
- SHA256: `5bc84e78b93c0f509f01c3b9513da5b7d475cdd8740c936882e3f53caea99105`

### 1.2.6

- Support config security patch date in `/data/adb/vbmetadisguiser/vbmeta.conf` you want to disguise too
- 支持在 `/data/adb/vbmetadisguiser/vbmeta.conf` 内配置想要伪装的安全补丁日期
- TrickyStore's configuration has the highest priority, with VBMeta Disguiser's built-in configuration (`/data/adb/vbmetadisguiser/vbmeta.conf`) coming second
- [TrickyStore](https://github.com/5ec1cff/TrickyStore)的配置优先级最高，其次才是VBMeta Disguiser的 `/data/adb/vbmetadisguiser/vbmeta.conf` 内置的配置
- Update the module description
- 更新模块描述
- Fix minor issues
- 修复一些细节问题
- SHA256: `6e6895d06533705a097dd71ac355b249b1036b7a30fabc216d8b8e6ec04b5ab0`

### 1.2.5

- Support disguising the security patch date configuring in `/data/adb/tricky_store/security_patch.txt` from [TrickyStore](https://github.com/5ec1cff/TrickyStore)
- 支持针对 [TrickyStore](https://github.com/5ec1cff/TrickyStore) 配置于 `/data/adb/tricky_store/security_patch.txt` 的安全补丁日期进行 resetprop
- NOTICE: This module will disguise the props ONLY. If you want to disguise the result from TEE, you need to install TrickyStore and configure it in `/data/adb/tricky_store/security_patch.txt` first.
- 注意：该模块仅伪装属性值。如果你需要伪装从TEE返回的结果，你需要安装 [TrickyStore](https://github.com/5ec1cff/TrickyStore) 并配置 `/data/adb/tricky_store/security_patch.txt`
- update the module description
- 更新模块描述
- SHA256: `dcca4968dae26c17d6d165a94078eba7c38a52f4f0ff2e1725960ab26d058268`

### 1.2.4

- Sync the update of `aautilities.sh` from Bloatware Slayer
- 同步更新 Bloatware Slayer 的实用工具库
- Fix the problems of some logical loophole
- 修复一些逻辑漏洞问题
- Add action.sh as shortcut to open the config directory with root file managers
- 新增 `action.sh` 以便于快捷用 `Root` 文件相关的管理器打开配置文件目录
- SHA256: `821402c8e6ab6f63ce5da9089a4569386565121c663b25ab826c3e9b781c3de8`

### 1.2.3

- Add the security check for config file / 增加对配置文件的安全检查
- Sync the changes of aautilities.sh / 同步 `aautilities.sh` 的变更
- Remove Bash ONLY code and enhance the compatibility for POSIX shell / 移除 Bash 专属代码，增强了对 POSIX shell 的兼容性
- Several minor changes / 若干细微改动
- SHA256: `102d6b4163fe5cc4b07da8f4e19e7894abf1a736b5d5372513fd36cfce0c34db`

### 1.2.2

- Add the security check for config file / 增加对配置文件的安全检查
- Several minor changes / 若干细微改动
- SHA256: `a79236bf7458f591cd9b74a78fa57d800eae897b4b1ea020757cb6b1a74f967f`

### 1.2.1
- Merge the props of VBMeta and Data Encryption
- 合并 VBMeta 和 数据加密 的属性值
- SHA256: `681414d73c237680fdc83b1862b97ebbdf72c70dd9b6681a68f93ca4ff407007`

### 1.2.0
- Initial build / the first page
  第一页

SHA256: `f64dc62016978dacff3f54d5c044422fe3681763401e6057b9b4693f968adeb6`
