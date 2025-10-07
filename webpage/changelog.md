## VBMeta 伪装者 / VBMeta Disguiser
一个用于伪装 VBMeta 属性的 Magisk 模块 / A Magisk module to disguise the properties of vbmeta

### 1.3.9

- Change the module id `vbmetadisguiser` -> `vbmeta_disguiser` for standardizing
- Remove all the logging codes
- Enhance the ability of spoofing build fingerprint
- Add new features: spoofing ROM build type as user/release-key build
- Add new features: outdated PiHooks/PixelProps properties removal
- Remove: Removed spoofing user/release-key in post-fs-data stage since it will cause serious problem
- Optimize the order of executing spoofing
- Happy Mid-Autumn Festival and National Day!

---

- 为了规范化，变更模块ID: `vbmetadisguiser` -> `vbmeta_disguiser`
- 移除所有日志代码
- 增强伪装构建指纹的能力
- 新增功能：伪装 ROM 的构建类型为 user/release-key 构建
- 新增功能: 移除过时的 PiHooks / PixelProps 属性值
- 移除：由于在 post-fs-data 阶段中伪装构建类型会导致严重问题，现已移除在该阶段的伪装函数
- 优化执行伪装顺序
- 中秋节、国庆节快乐！