## VBMeta 伪装者 / VBMeta Disguiser

一个用于伪装 VBMeta 属性、加密状态和系统安全补丁日期的 Magisk 模块
/ A Magisk module to disguise the props of vbmeta, encryption status and security patch date

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
