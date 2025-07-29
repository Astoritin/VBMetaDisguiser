## VBMeta 伪装者 / VBMeta Disguiser
一个用于伪装 VBMeta 属性的 Magisk 模块 / A Magisk module to disguise the properties of vbmeta

### 1.3.7

- No more background task to sync the changes of config file
- Instead, VBMeta properties will update manually by clicking on action/open button
- Fix the issue of security patch date properties not working
- Use new method to analyse security patch date
- Use new method to update module description
- Add config for spoofing properties of bootloader status as locked into `vbmeta.conf` (disable by default)
- Add config for spoofing properties of ROM build type as user/release into `vbmeta.conf` (disable by default)
- Add debug logs code

---

- 不再执行同步配置文件变更的后台任务
- 作为替代，VBMeta 的属性值会在手动点击操作/打开按钮时被更新
- 修复安全补丁日期属性值不生效的问题
- 使用新方法分析安全补丁日期
- 使用新方法更新模块描述
- 新增伪装bootloader状态属性值为已锁定的配置至 `vbmeta.conf` (该功能默认禁用)
- 新增伪装ROM的构建类别属性值为user/release的配置至 `vbmeta.conf` (该功能默认禁用)
- 添加调试用日志代码