# lmi postmarketOS 资料池

> 状态（2026-10-24）：本文是 2026-10-23 的资料汇总。电池电量计已在 2026-10-24 启用（见 `06-runtime.md`）；下文“部分支持”矩阵里的“fuel-gauge 未接”指的是社区当时的版本。

- 记录日期：2026-10-23
- 用途：锁定评估时看到的上游/社区状态，避免以后把“当时的状态”当成“现在的事实”
- 规则：首次实际使用时，把下面每个仓库的 commit 再固定一次；本文的 commit 只是评估时的快照

---

## 1. 上游与官方状态

| 对象 | 地址 | 评估时状态 |
|---|---|---|
| postmarketOS Wiki lmi 页 | https://wiki.postmarketos.org/wiki/Xiaomi_POCO_F2_Pro_(xiaomi-lmi) | `packaged = no`，`booting = yes`；功能表见下 |
| postmarketOS Wiki SM8250 页 | https://wiki.postmarketos.org/wiki/Qualcomm_Snapdragon_865/865%2B/870_(SM8250) | SoC 主线 `Mainline: yes`；列出 xiaomi-lmi；开发树指向 `gitlab.postmarketos.org/soc/qualcomm-sm8250/linux` |
| 官方 pmaports | https://gitlab.postmarketos.org/postmarketOS/pmaports | 默认分支 `main`；`device/testing`、`device/community`、`device/unmaintained` 均无 `device-xiaomi-lmi`（2026-10-23 核对） |
| 官方 pmaports：SM8250 内核 | `device/testing/linux-postmarketos-qcom-sm8250` | 存在；服务已上游的 SM8250 设备 |
| 官方 pmaports：参考设备 | `device/testing/device-xiaomi-elish` | 存在；可作为设备包写法参考 |
| 主线内核 qcom DTS | https://github.com/torvalds/linux/tree/master/arch/arm64/boot/dts/qcom | 有 `sm8250-xiaomi-elish-boe/csot`、`sm8250-xiaomi-pipa`，**无 `sm8250-xiaomi-lmi.dts`**；`Makefile` 无 lmi 条目 |
| pmbootstrap | https://gitlab.postmarketos.org/postMarketOS/pmbootstrap | `flasher` 默认把 rootfs 写到 `flash_fastboot_partition_rootfs`，未设置时为 `userdata` |

### Wiki 功能表原文要点（lmi）

- 可用：Screen（60Hz）、Touchscreen（FocalTech FT3518 @ 0x38，i2c13）、Internal storage（UFS 2.0 + sm8250 QMP UFS PHY）、GPU（Adreno 650）、USB OTG、Charging、Audio、Camera Flash、IR TX、Wi-Fi（QCA6391）、Bluetooth（QCA）、NFC（NQ-NCI @ 0x28，i2c1）、Sensors（Accelerometer / Magnetometer / Ambient Light）
- 不可用：GPS、Modem（Calls/SMS/Data）、Fingerprint、Proximity、Haptics
- 部分：Camera
- 已知问题：**Changing brightness causes graphical artifacts**
- 备注：Modem 是 SDX55m，mainline 不支持；GPU 需要 a650（unsigned）与 a650-zap（signed）firmware；Wi-Fi 需要 ath11k（unsigned）firmware；BT 需要 qca firmware；传感器依赖 hexagonrpcd + libSSC + 签名 SDSP firmware

---

## 2. postmarketOS 社区移植（Nikroks / yuweiyuan8）

| 对象 | 地址 | 评估时 commit / 版本 |
|---|---|---|
| pmaports fork | https://github.com/yuweiyuan8/pmaports | 分支 `nikroks/alioth`，commit `b6453d5`；`master` 也含 lmi 包 |
| 设备包 | `device/testing/device-xiaomi-lmi` | `pkgver=1`，`pkgrel=0`；维护者 Nikroks |
| 内核包 | `device/testing/linux-postmarketos-qcom-sm8250-lmi` | `pkgver=6.19.7`，`pkgrel=0`；源 `https://github.com/yuweiyuan8/linux/archive/v6.19/...` |
| 固件包 | `device/testing/firmware-xiaomi-lmi` | 存在 |
| 内核仓库 | https://github.com/yuweiyuan8/Linux-redmi-k30pro-6.19 | `v6.19` 分支，commit `999ef8b`；旧名 `yuweiyuan8/linux` 会重定向 |
| nightly 构建 | https://github.com/yuweiyuan8/lmi-nightly-builds | `main`，commit `83e043b`；每周五 cron；产物 `boot-xiaomi-lmi.img` + `rootfs-xiaomi-lmi.img`，保留 7 天 |
| 固件仓库 | https://github.com/yuweiyuan8/firmware-xiaomi-lmi | 用于 `firmware-xiaomi-lmi` 包 |
| 旧工程（2024） | https://github.com/yuweiyuan8/pmos_xiaomi_lmi | `mainline` 分支；`device-xiaomi-lmi` + `linux-xiaomi-lmi`；已被上面的 pmaports fork 取代 |

### 设备包关键内容

`deviceinfo`：

```
deviceinfo_codename="xiaomi-lmi"
deviceinfo_arch="aarch64"
deviceinfo_dtb="qcom/sm8250-xiaomi-lmi"
deviceinfo_append_dtb="true"
deviceinfo_flash_method="fastboot"
deviceinfo_generate_bootimg="true"
deviceinfo_bootimg_qcdt="false"
deviceinfo_header_version="2"
deviceinfo_flash_pagesize="4096"
deviceinfo_super_partitions="/dev/sda36 /dev/sda36"
deviceinfo_flash_sparse="true"
deviceinfo_rootfs_image_sector_size="4096"
```

`APKBUILD` 依赖：

```
alsa-ucm-conf  bootmac  hexagonrpcd  make-dynpart-mappings
mesa-vulkan-freedreno  mkbootimg  swclock-offset
linux-postmarketos-qcom-sm8250-lmi  postmarketos-base  qbootctl
```

nonfree firmware 子包依赖：

```
firmware-xiaomi-lmi  firmware-qcom-adreno-a650  linux-firmware-qcom
linux-firmware-qca  linux-firmware-ath11k  tqftpserv
```

`modules-initfs`：

```
panel-samsung-ams667xx01
panel-samsung-ams667uu01
```

nightly 工作流要点：

- `pmbootstrap` 从 gitlab.postmarketos.org 克隆
- pmaports 缓存 reset 到 `mainlining/nikroks/alioth`
- 内核分支 `6.19.2`，用 `envkernel` 构建
- `pmbootstrap install --password <password>`
- 导出 `boot.img` 和 `xiaomi-lmi.img`
- 产物保留 7 天

### 设备包启动方式

- boot image：header v2，`base=0x00000000`，`kernel_offset=0x00008000`，`ramdisk_offset=0x01000000`，`dtb_offset=0x01f00000`，追加 DTB
- rootfs：pmbootstrap 未设置 `flash_fastboot_partition_rootfs`，默认写 `userdata`
- 因此默认单系统会清空 Android 数据；Android 的 boot 被 Linux 占用

---

## 3. 更活跃的主线移植（ccc007ccc / electropica）

| 对象 | 地址 | 评估时 commit / 版本 |
|---|---|---|
| 内核 | https://github.com/ccc007ccc/linux-sm8250-xiaomi-lmi | master `3a8409f`；Makefile 7.1.0；boot 工具锁定已验证内核 **6.18.30 LTS**（commit `52dc660`，2026-05-14） |
| boot 工具 | https://github.com/ccc007ccc/sm8250-xiaomi-lmi-boot | master `31e6156`；含 copydown bootshim、mkbootimg 参数、fastboot 包装 |
| initramfs | https://github.com/ccc007ccc/sm8250-xiaomi-lmi-initramfs | master `ca90a15`；UFS rootfs 扫描、启动菜单、next-boot、recovery/fastbootd |
| rootfs | https://github.com/ccc007ccc/sm8250-xiaomi-lmi-rootfs | master `f71e310`；Ubuntu 26.04 / Fedora KDE、partition-geometry、lmi-power |
| 用户态/验证文档 | https://github.com/electropica/xiaomi-lmi-linux-port | main `3cff40d`；Debian 13 + Phosh；`docs/validation/` 有 2026-09 的硬件验证 |
| 硬件矩阵 | `lmi/HARDWARE_SUPPORT.md`（内核仓库） | 本次评估的主要依据之一 |
| 使用教程 | `lmi/docs/USAGE.md` | rootfs 放 `/dev/sda34`，标签 `ubuntu-rootfs`；`fastboot flash boot` |
| 构建/打包 | `lmi/docs/BUILD_AND_PACKAGING.md` | 内核 release 构建、initramfs、boot 打包、manifest |
| 相机 bring-up | `lmi/CAMERA_BRINGUP.md` | OV13B10 raw + 用户态 ISP/UVC |
| modem bring-up | `lmi/MODEM_BRINGUP.md` | SDX55 SBL/Sahara/MHI 诊断，未到 Mission/AMSS |

### 启动链路

```
Android boot image
  -> copydown bootshim
  -> Linux Image.gz + sm8250-xiaomi-lmi.dtb
  -> 内嵌 initramfs
  -> 扫描 UFS 上的 Linux rootfs
  -> switch_root 进入发行版
```

### 设备基线（作者机器，非通用基线）

`locks/device-baseline.lock`：

```
device=Redmi K30 Pro / POCO F2 Pro lmi
soc=sm8250
android_release=16
boot_partition_size=134217728      # 128 MiB
dtbo_partition_size=33554432       # 32 MiB
recovery_partition_size=134217728  # 128 MiB
vbmeta_partition_size=131072       # 128 KiB
boot_header_version=2
boot_page_size=4096
boot_kernel_addr=0x00008000
boot_ramdisk_addr=0x01000000
boot_tags_addr=0x00000100
boot_dtb_size=1634146
boot_dtb_addr=0x0000000001f00000
dtb_delivery=boot-image-dtb-field
```

结论：lmi 是单 boot / 单 recovery / 单 dtbo / 单 vbmeta（A-only），不是 A/B。`deviceinfo_super_partitions="/dev/sda36 /dev/sda36"` 和设备包里的 `qbootctl` 可能是从 alioth 设备包继承，实际以本机 `fastboot getvar all` 为准。

### 硬件矩阵摘要（原文）

- **已支持**：UFS/rootfs、屏幕/DRM（AMS667UU01，60/77Hz，fbcon/KMS/背光）、GPU（A650/GMU/freedreno，GBM/EGL/GLES/KMS）、触摸（FT3518，i2c13）、实体按键、Wi-Fi（QCA6391，ath11k_pci）、蓝牙（QCA6391 UART）、Docker/容器内核能力
- **部分支持**：Venus 视频编解码（H.264 编码 bring-up）、USB/Type-C（gadget/ACM/PD sink，host 未完全验证）、电池/充电（PM8150B/SMB5/fuel-gauge，私有快充/BQ2597x 未接）、主扬声器（调试机扬声器物理损坏）、3.5mm HPH、机身麦克风、调制解调器（仅诊断）、摄像头（OV13B10 raw + UVC）
- **待适配**：NFC、传感器、触觉、闪光灯、SBA-MUX
- **暂不支持**：充电泵/私有快充

### 明确边界（原文）

- modem：SDX55M 只到 PCIe2/MHI/signed SBL/Sahara HELLO/部分 image transfer，**未进入 Mission/AMSS**；SIM、蜂窝数据、语音、IMS/VoLTE、ModemManager 均不可用
- 相机：kernel 边界仍是 raw RDI/Bayer `/dev/video3 pgAA`；SM8250 mainline CAMSS 无完整 ISP/YUV/RGB；用户态 software-ISP/loopback/UVC 是独立节点；PipeWire/browser `getUserMedia` 未验证；前摄和其他后摄未启用
- 不建议：进入 EDL、发送 firehose、写 NV/modem/dtbo/recovery/vbmeta

---

## 4. 设备与 Android 侧参考

| 对象 | 地址 | 用途 |
|---|---|---|
| LineageOS lmi 设备树 | https://github.com/LineageOS/android_device_xiaomi_lmi (`lineage-23.2`) | 屏幕密度 440、OTA assert lmi、内核 config 片段 |
| LineageOS sm8250-common | https://github.com/LineageOS/android_device_xiaomi_sm8250-common (`lineage-23.2`) | `AB_OTA_UPDATER`、super 分区、fstab；lmi 未设 `TARGET_IS_VAB`，走 `fstab.qcom`（非 A/B） |
| MIUI 线刷包 | https://old.miuier.com/devices/lmi | 恢复源；记录版本与哈希，优先用与当前系统匹配的地区/版本 |
| 主线 qcom DTS 目录 | https://github.com/torvalds/linux/tree/master/arch/arm64/boot/dts/qcom | 确认 lmi 未上游 |
| 主线 panel Makefile | https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/drivers/gpu/drm/panel/Makefile | 无 ams667uu01 |
| 主线 touchscreen Makefile | https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/drivers/input/touchscreen/Makefile | 无 FocalTech FT3518 |
| 主线 power/supply Makefile | https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/drivers/power/supply/Makefile | 无 bq2597x |
| 主线 ASoC codecs Makefile | https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/sound/soc/codecs/Makefile | 无 tfa9874 |
| 主线 qcom SoC Makefile | https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/drivers/soc/qcom/Makefile | 无 ESOC 驱动 |

---

## 5. 设备证据清单（2026-10-24 更新）

- [x] `fastboot getvar all` 全量输出（`原始输出未上传；分区表见 03-device-audit.md`）
- [x] `adb shell ls -l /dev/block/by-name/` 分区表（`03-device-audit.md`）
- [x] `adb shell dmesg | grep -iE 'panel|ams667|ft3518|focaltech'` 面板/触控型号（Linux 启动后确认 AMS667UU01 / FT3518）
- [x] `adb shell getprop` 关键属性（device/model/release/hardware）
- [x] 两个 LUN 的 GPT 主备表
- [x] boot/dtbo/vbmeta/recovery/persist/modem/dsp/bluetooth/misc 备份及哈希（`<local-backups>/`）
- [x] MIUI 线刷包版本（HyperOS 3 `OS3.0.301.0.WJKCNXM`；哈希未核对）
- [ ] 电池健康/循环次数（UPower 显示 `charge-cycles: N/A`，当前驱动读不到）
- [x] 设备当前槽位/解锁状态/anti-rollback（A-only，`unlocked: yes`）
