# Redmi K30 Pro（lmi）移植 postmarketOS 可行性评估

> 状态（2026-10-24）：本文是 2026-10-23 的立项评估，保留原文。实际启动与运行状态见 `05-flash-and-first-boot.md` 和 `06-runtime.md`；计划中的“首版只碰 boot 和 userdata”因 boot 分区 AVB 拒绝，实际调整为同时写 `recovery`。

- 评估日期：2026-10-23
- 设备：Redmi K30 Pro / K30 Pro 变焦版 / POCO F2 Pro，代号 `lmi`，SoC 为 Qualcomm SM8250（Snapdragon 865）
- 前提：Bootloader 已解锁（已满足）
- 评估范围：只做资料核对与路线评估，**没有连接或改动设备**
- 结论有效期：社区仓库变化很快；本文所有“支持/不支持”都只代表 2026-10-23 能看到的状态，必须在目标设备上复验

---

## 0. 一句话结论

**能跑，而且不用从零移植：社区已经有可复用的 lmi 主线 Linux 移植，显示、触控、Wi-Fi、蓝牙、GPU、UFS 启动、基础充电都已有人跑通。**

**但把它当“日常手机”目前不成立：外挂的 SDX55m 蜂窝 modem 主线不支持，SIM/通话/短信/移动数据全部不可用；GPS、屏下指纹、接近光、振动、完整相机也不可用。**

更准确的定位是：

| 目标 | 可行性 | 说明 |
|---|---|---|
| 跑起 postmarketOS，USB/SSH 进去，当 Linux 掌上设备 | **高** | 现有 pmOS 社区移植可复用；预计 2–5 天首次启动 |
| 当带触摸屏的 Linux 小服务器 / 开发板 | **高** | 显示、Wi-Fi、SSH、Docker 能力都有人验证过 |
| 当日常手机（电话、短信、移动数据、相机、支付） | **目前不可行** | modem 是硬阻塞，不是短期调参能解决的 |
| 长期维护 / 上游化 | **中等偏低** | 面板、触控、充电泵、codec、ESOC 等驱动都在树外，且不在官方 pmaports |

---

## 1. 先澄清三个容易误会的点

1. **postmarketOS 官方没有 lmi**
   - 官方 pmaports 的 `device/testing`、`device/community`、`device/unmaintained` 都没有 `device-xiaomi-lmi`。
   - postmarketOS Wiki 的 lmi 页面标记为 `packaged = no`、`booting = yes`。
   - 所以 `pmbootstrap init` 默认看不到 lmi；要用社区 fork 或自己加设备包。

2. **主线内核上游没有 lmi 设备树**
   - Torvalds 主线 `arch/arm64/boot/dts/qcom` 里，SM8250 的小米设备目前只有 `sm8250-xiaomi-elish`（小米平板 5 Pro）和 `sm8250-xiaomi-pipa`（小米平板 6），没有 `sm8250-xiaomi-lmi.dts`。
   - lmi 的 DTS 在社区 fork 里，属于“基于主线的树外设备树”，不是上游已合入。

3. **现有移植不止一个，且成熟度不同**
   - 一条是 **postmarketOS 设备包**（Nikroks / yuweiyuan8），内核 6.19.7，Phosh，最接近你“移植 postmarketOS”的目标。
   - 另一条是 **更活跃的 Debian/Ubuntu/Mobian 主线移植**（ccc007ccc / electropica），内核锁定 6.18 LTS（仓库 master 已到 7.1 开发线），硬件验证文档更完整，但它不是 pmOS。
   - 两条路可以互相借用内核、DTS、firmware 和启动经验，但**不能直接混刷**。

---

## 2. 现有移植证据

### 2.1 postmarketOS 社区移植（最直接的复用对象）

| 项目 | 内容 |
|---|---|
| 设备包 | `device/testing/device-xiaomi-lmi` |
| 内核包 | `linux-postmarketos-qcom-sm8250-lmi`，`pkgver=6.19.7` |
| 固件包 | `firmware-xiaomi-lmi`（另有 Adreno A650、linux-firmware-qcom/qca/ath11k） |
| pmaports 分支 | `yuweiyuan8/pmaports` 的 `nikroks/alioth` 分支，commit `b6453d5` |
| 内核仓库 | `yuweiyuan8/Linux-redmi-k30pro-6.19`，`v6.19` 分支，commit `999ef8b` |
| 自动构建 | `yuweiyuan8/lmi-nightly-builds`，每周五构建 `boot.img` + rootfs 镜像，默认用户 `user`，密码 `<password>` |
| Wiki 状态 | `packaged=no`、`booting=yes`；屏幕 60Hz、触控、USB OTG、充电、UFS、3D、音频、Wi-Fi、蓝牙、NFC、加速度/磁力/光线传感器可用；GPS、modem、指纹、接近光、振动不可用；相机部分可用；已知亮度变化导致花屏 |
| 最后代码活动 | 2026-02（pmaports / kernel）；nightly 工作流之后是否还在产出需要实测 |

设备包依赖（说明它不是“裸内核”）：

```
alsa-ucm-conf  bootmac  hexagonrpcd  make-dynpart-mappings
mesa-vulkan-freedreno  mkbootimg  swclock-offset
linux-postmarketos-qcom-sm8250-lmi  postmarketos-base  qbootctl
```

启动方式：`fastboot` + boot image（header v2，追加 DTB），rootfs 默认写到 `userdata`（pmbootstrap 的 `$PARTITION_ROOTFS` 缺省值），所以**默认单系统会清空 Android 数据**。

### 2.2 更活跃的主线移植（Debian/Ubuntu/Mobian，不是 pmOS）

| 项目 | 内容 |
|---|---|
| 内核 | `ccc007ccc/linux-sm8250-xiaomi-lmi`，master `3a8409f`；boot 工具锁定已验证内核 **6.18.30 LTS**，仓库 master Makefile 已到 7.1 开发线 |
| 启动工具 | `sm8250-xiaomi-lmi-boot`（copydown bootshim、boot image 打包、fastboot 辅助） |
| initramfs | `sm8250-xiaomi-lmi-initramfs`（UFS rootfs 扫描、启动菜单、next-boot、recovery/fastbootd 入口） |
| rootfs | `sm8250-xiaomi-lmi-rootfs`（Ubuntu 26.04 Server / Fedora KDE 构建、分区几何、`lmi-power` 限充） |
| 用户态 | `electropica/xiaomi-lmi-linux-port`（Debian 13 + Phosh，2026-09 仍有硬件验证记录） |
| 启动链路 | Android boot image → copydown bootshim → `Image.gz` + `sm8250-xiaomi-lmi.dtb` → 内嵌 initramfs → UFS rootfs |
| 推荐 rootfs 落点 | `/dev/sda34`，标签 `ubuntu-rootfs`；兼容 `/dev/sda35` / `PARTNAME=linuxroot` |
| 已验证 | 60/77Hz 显示、FT3518 触控、QCA6391 Wi-Fi/BT、A650 freedreno、Docker/cgroup v2、USB ACM、PD 9V/2A、听筒/3.5mm/两路麦克风、Venus H.264 编码（bring-up） |
| 部分/未支持 | modem 仅到 SBL/Sahara/MHI 诊断，未进入 Mission/AMSS；相机仅 OV13B10 raw + 用户态 UVC；NFC/传感器/振动/闪光灯未接入；33W 私有快充/BQ2597x 未接入 |

这条线最有价值的不是“直接刷”，而是它把 lmi 的**启动链、分区、显示、音频、电源、modem 诊断**写成了可复用的文档和代码。若你要把 pmOS 做到长期可用，最终大概率要吸收它的内核/DTS/启动经验。

---

## 3. 硬件支持矩阵

“pmOS 社区移植”一列来自 postmarketOS Wiki；“主线移植”一列来自 ccc007ccc 的 `HARDWARE_SUPPORT.md`。两列都未在目标设备上复验。

| 功能 | pmOS 社区移植 | 主线移植（Debian/Ubuntu） | 结论/备注 |
|---|---|---|---|
| 启动 / UFS rootfs | 可用 | 可用 | 都需要解锁 BL；pmOS 默认写 userdata |
| 屏幕 | 60Hz 可用；亮度变化花屏 | 60Hz + 77Hz；HBM/DC dimming/doze/ESD 未接 | 面板 AMS667UU01；换屏机需确认面板型号 |
| 触控 | 可用 | FT3518 多点触控可用 | i2c13 / GENI I2C |
| GPU | 可用（mesa-vulkan-freedreno） | A650/GMU/freedreno + GBM/EGL/GLES/KMS | 需要 A650 firmware/zap |
| Wi-Fi | QCA6391 可用 | ath11k_pci，自动连接 + SSH 已验证 | 需要匹配 firmware |
| 蓝牙 | 可用 | QCA6391 UART，BR/EDR + LE 基础能力 | 地址设置策略仍有工作 |
| 音频 | Wiki 标记可用 | 主扬声器部分（调试机扬声器物理损坏）、听筒/3.5mm/两路麦克风可用 | pmOS 侧麦克风/耳机路径未细验 |
| 充电 | 可用（基础） | PM8150B/SMB5/fuel-gauge 可用；33W 私有快充/BQ2597x 未接 | 长期插电建议 65–70% 限充 |
| USB | OTG 可用 | gadget/ACM/PD sink 9V/2A；host/角色切换部分 | 单 Type-C 口，测 host 前先有 Wi-Fi SSH |
| NFC | Wiki 标记可用 | 未接入 | pmOS 侧来自下游节点，需复验 |
| 传感器 | 加速度/磁力/光线可用，接近光不可用 | 未启用（需 SDSP + 签名 firmware + hexagonrpcd） | 两套方案不同，别混用 |
| 红外 / 闪光灯 | Wiki 标记可用 | 闪光灯未接入；红外未在矩阵中 | 非核心 |
| 相机 | 部分可用 | 仅 OV13B10 raw + 用户态 UVC/软件 ISP；主摄/前摄未启用 | 没有完整 ISP/YUV，不能当手机相机 |
| 蜂窝 modem | 不可用 | 仅诊断（SBL/Sahara/MHI，未到 Mission/AMSS） | **硬阻塞**：SIM/通话/短信/数据/IMS 都不可用 |
| GPS | 不可用 | 不可用 | — |
| 屏下指纹 | 不可用 | 不可用 | — |
| 触觉/振动 | 不可用 | 未接入 | AW8697 |
| 休眠/待机 | 未在 Wiki 标注 | 有 gsd-power 误唤醒的用户态规避；完整 suspend 未验证 | 不要按“手机待机”预期 |
| Docker/服务器 | 未验证 | 已验证 overlayfs/cgroup v2/bridge/NAT/端口映射 | 这是 lmi 当前最实用的场景 |

---

## 4. 核心限制与硬阻塞

### 4.1 蜂窝 modem（最大阻塞）

- lmi 用的是外挂 **SDX55m**，不是 SoC 内置 modem；主线没有可用的 SDX55m 蜂窝栈。
- 社区目前只推进到 PCIe/MHI/SBL/Sahara 和多阶段 image transfer 诊断，**没有进入 Mission/AMSS**。
- 结果：没有 SIM、没有蜂窝数据、没有通话/短信、没有 IMS/VoLTE，ModemManager 也不可用。
- 这不是“再调几天”的问题；除非有人把 SDX55m 的 firmware 加载、QMI/QRTR、IPA、语音链路全部打通，否则不要期待手机功能。

### 4.2 相机

- 主线 SM8250 CAMSS 没有完整 ISP/YUV 输出；现有移植只做到 OV13B10 raw Bayer + 用户态软件 ISP/UVC。
- 主摄（IMX686）、前摄升降机构、其他后摄都未启用。
- 能“出图”不等于能当相机用；PipeWire/浏览器 `getUserMedia` 仍未验证。

### 4.3 树外驱动

lmi 的以下关键驱动不在主线：

- 面板：`panel-samsung-ams667uu01`（主线 Makefile 里没有）
- 触控：FocalTech FT3518（主线没有对应驱动）
- 充电泵：BQ2597x（主线没有）
- 代码：TFA9874（主线 ASoC Makefile 里没有）
- ESOC/SDX55：主线 `drivers/soc/qcom` 里没有对应 ESOC 驱动

这意味着：

- 内核升级要跟着 fork 走，不能直接换成官方 `linux-postmarketos-qcom-sm8250`。
- 上游化是独立的大工程，不是“提个 DTS 就完事”。

### 4.4 不是官方支持

- 官方 pmaports 没有 lmi；官方 SM8250 内核包只服务 elish/pipa 等已上游设备。
- 现有 pmOS 移植是个人 fork，nightly 构建也可能因仓库长期无推送而停摆。
- 出问题没有官方 issue 渠道，主要靠读代码和自己复现。

### 4.5 显示与电源

- pmOS 社区移植的已知问题：**调亮度会花屏**；只验证 60Hz。
- 主线移植把显示做到 60/77Hz，但 HBM、DC dimming、doze、完整 ESD 恢复仍未接。
- 休眠/待机没有完整验证；不要期待 Android 级别的待机功耗。

### 4.6 分区与双系统

- lmi 是 **A-only + super 动态分区**（LineageOS sm8250-common 走非 VAB 的 `fstab.qcom`，设备树未设 `TARGET_IS_VAB`；boot/recovery/dtbo 都是单分区）。设备包里的 `qbootctl` 很可能是从 alioth 设备包继承的，实际以 `fastboot getvar` 为准。
- pmbootstrap 默认把 rootfs 写到 `userdata`，会清空 Android 数据；Android 系统分区（super）还在，但 boot 被 Linux 占用，不刷回 Android boot 就进不了 Android。
- 想双系统，需要在 userdata 尾部划出 Linux 分区（ccc 的 `partition-geometry.py` 就是干这个的），或者接受“用 fastboot 换 boot 镜像”的冷切换。两种都比单系统风险高，首版不建议做。

---

## 5. 三条路线与建议

### 路线 A：复用现有 postmarketOS 移植（推荐用于“先跑起来”）

做法：

1. 用 `yuweiyuan8/pmaports` 的 `nikroks/alioth` 分支替换 pmbootstrap 的 pmaports 缓存（或把设备包/内核包/firmware 包复制进自己的 pmaports）。
2. `pmbootstrap init` 选 `xiaomi-lmi`、`phosh`；构建内核 + rootfs。
3. `fastboot flash boot boot.img`；`fastboot flash userdata rootfs.img`。
4. 首次启动后用 USB 网络或 Wi-Fi SSH 进去，逐项验收显示、触控、Wi-Fi、音频、充电（实际使用 Wi-Fi + root SSH，USB 网络未验证）。

预计：首次启动 2–5 天（含备份/恢复演练），较稳定 2–3 周。  
优点：真正是 postmarketOS，设备包齐全，有 nightly 构建脚本可参考。  
缺点：内核 6.19.7 偏旧、树外驱动多、亮度花屏、无 modem、维护者活跃度有限。

### 路线 B：以主线移植的 6.18 LTS 内核为基座，自己集成 pmOS

做法：

1. 以 `ccc007ccc/linux-sm8250-xiaomi-lmi` 的 6.18.30 验证配置 + DTS + 补丁为内核基线。
2. 把 pmOS 设备包的内核依赖换成自己的 `linux-postmarketos-qcom-sm8250-lmi`，保留 pmOS 的 boot-deploy/initramfs 体系；吸收 ccc 的 bootshim、显示、音频、电源、modem 诊断经验。
3. 先做单系统 Ubuntu/Debian 验证硬件，再把用户态换成 pmOS/Phosh；或者直接把 pmOS rootfs 塞进 ccc 的 UFS rootfs 启动链。

预计：首次可用 3–6 周，稳定 2–3 个月。  
优点：内核更新、文档完整、硬件验证更细、后续维护性更好。  
缺点：集成工作量大；两套启动链（pmOS boot-deploy vs copydown shim）需要统一；仍然没有 modem。

### 路线 C：从零按主线 bring-up + 上游化

预计 3–6 个月起，且 modem/相机仍可能无解。除非目标是“把 lmi 做成上游支持设备”，否则不建议作为首版路线。

**建议：先用 A 把设备跑起来、把备份和恢复链路走通；确认自己确实需要长期使用时，再转 B。不要一上来做 C。**

---

## 6. 工作量估算（路线 A）

| 阶段 | 内容 | 预计 |
|---|---|---|
| 0 立项/备份 | 设备身份、`getvar all`、GPT/关键分区备份、MIUI 线刷包恢复演练 | 0.5–1 天 |
| 1 构建环境 | WSL2/Ubuntu 26.04 装 pmbootstrap、ccache、复现社区内核 | 0.5–1 天 |
| 2 首次启动 | 构建 boot/rootfs、fastboot 刷入、USB SSH、冷启动 | 1–2 天 |
| 3 基础外设 | 显示/触控/亮度、Wi-Fi/BT、音频、充电、按键 | 1–2 周 |
| 4 稳定化 | 休眠/功耗、热、回滚、Android 恢复、双系统（可选） | 1–2 周 |
| 5 modem/相机 | 研究性工作 | 数月，且不保证成功 |

首次“能跑”约 **2–5 天**；达到“日常 Linux 小设备”约 **2–4 周**；达到“手机”无时间表。

---

## 7. 风险与退路

| 风险 | 影响 | 缓解 |
|---|---|---|
| 清空 userdata | Android 数据丢失 | 先备份；保留 MIUI 线刷包；首版单系统 |
| boot 被 Linux 占用 | 不能直接回 Android | 备份 stock boot/dtb/vbmeta；用 fastboot 刷回；或线刷恢复 |
| 分区/GPT 操作（双系统） | 高，可能变砖 | 首版不做；必须做时先备份 GPT、逐分区校验、用维护镜像 |
| 面板型号不符 | 黑屏/花屏 | 先用 `dmesg`/`/sys` 确认 AMS667UU01；换屏机先查面板 |
| 固件不匹配 | Wi-Fi/BT/GPU 起不来 | 用与固件包匹配的 stock firmware；不要混用不同 MIUI 版本 |
| pmOS fork 停更 | 无法跟内核/发行版更新 | 锁定 commit；保留主线移植作为后备 |
| 无蜂窝 | 不能当手机 | 明确用途；需要手机功能就保留 Android 或换机 |
| 待机/发热 | 电池老化、体验差 | 先按服务器/桌面用；限充 65–70%；验证 suspend 前不要长期放包里 |

**退路**：解锁 BL 的 Xiaomi 设备，只要不进 EDL 乱写、不动 `persist`/`modem`/`xbl` 等关键分区，最坏情况通常可以用 MIUI 线刷包恢复。原计划首版只碰 `boot` 和 `userdata`；实际因 boot AVB 拒绝，额外写了 `recovery`（见 `05-flash-and-first-boot.md`）。

---

## 8. 开工前必须确认的事项（不动设备也能先做一部分）

1. **设备身份**
   - `adb shell getprop ro.product.device` 应为 `lmi`
   - `ro.product.model`、`ro.build.version.release`、`ro.boot.hardware`
   - 确认是 K30 Pro 标准版 / 变焦版 / POCO F2 Pro；存储 128/256GB、内存 6/8/12GB
2. **分区与槽位**
   - `fastboot getvar all`（重点看 `product`、`current-slot`、`has-slot:boot`、`unlocked`、`anti`、各分区大小）
   - `adb shell ls -l /dev/block/by-name/`（只读）
   - 确认 `boot/dtbo/vbmeta/recovery/super/userdata/persist/modem/dsp/bluetooth/misc` 都在
3. **面板/触控**
   - `adb shell dmesg | grep -iE 'panel|ams667|ft3518|focaltech'`
   - 确认面板是 AMS667UU01（或至少被现有驱动覆盖）
4. **备份**
   - 两个 LUN 的 GPT 主备表
   - `boot`、`dtbo`、`vbmeta`、`vbmeta_system`、`vbmeta_vendor`、`recovery`、`persist`、`modem`、`dsp`、`bluetooth`、`misc`
   - `super` 太大可用 MIUI 线刷包替代；`userdata` 按需（加密数据未必能直接读）
   - 主机与设备两侧哈希一致
5. **恢复源**
   - 下载对应地区/版本的 lmi MIUI 线刷包，校验哈希，先在 Android 上演练一次恢复流程
6. **主机环境**
   - pmbootstrap 需要 Linux；WSL2 Ubuntu 26.04 可用
   - fastboot 建议走 Windows `fastboot.exe`，或给 WSL2 配 usbipd
   - 预留 ≥100GB 磁盘；首次内核构建建议 8–16GB 内存 + ccache

---

## 9. 需要你决定的事项

1. **目标**：尝鲜/开发板/小服务器，还是日常手机？
2. **数据**：能否清空 userdata、暂时失去 Android？
3. **系统形态**：单系统 pmOS，还是必须保留 Android 双系统？
4. **路线**：A（现有 pmOS 移植）/ B（6.18 主线内核重做 pmOS 集成）/ C（从零上游化）？
5. **桌面**：Phosh / Plasma Mobile / GNOME / 无桌面（SSH）？
6. **调试通道**：USB SSH 默认开还是关？
7. **发布**：是否公开仓库、用什么许可证、原厂固件是否随仓库分发？
8. **无人值守**：你不在场时允许做哪些操作（只读、构建、刷机）？

确认后写入 `AGENTS.md`，后续不再重复问。

---

## 10. 参考来源

见 [02-sources.md](02-sources.md)。所有结论都来自公开仓库、Wiki 和静态核对；评估阶段没有在设备上执行命令。
