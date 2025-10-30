## VBMeta 伪装者 / VBMeta Disguiser
一个用于伪装 VBMeta 属性的 Magisk 模块 / A Magisk module to disguise the properties of vbmeta

### 1.4.0

- Migrate bootloader properties spoof to service.d
- Append feature: spoofing property ro.build.flavor
> It is not a standard property in stock ROMs though so I guess it is not so meaningful to disguise it...

---

- 将 Bootloader 属性值伪装迁移到 service.d 文件夹
- 追加功能：伪装属性值 ro.build.flavor
> 尽管这并不是一个会在原厂ROM中见到的标准属性值，伪装它我感觉意义不大……聊胜于无吧。