# 设备审计记录 — 2026-10-23

> 状态（2026-10-24）：本文是 Android 侧只读审计原文，保留作证据。第 5 节待确认项已在后续确认：面板 AMS667UU01、触控 FT3518、数据已备份、临时 root 环境已通过 TWRP/离线镜像完成、HyperOS 3 版本已记录。当前运行状态见 `05-flash-and-first-boot.md`、`06-runtime.md`。

- 设备：Redmi K30 Pro Zoom Edition（Android 产品名 `lmipro`）
- Bootloader 产品名：**`lmi`**
- 平台：SM8250 / `ro.product.mod_device=lmi` / 相机 sensor 名均为 `lmi_*`
- 结论：**属于 lmi 平台，现有 lmi 移植适用**；Zoom 多出的长焦相机本来就不在支持范围
- 注意：serial 已替换为占位符；本文件只保留平台、分区和硬件信息，可公开

---

## 1. Android 侧

| 项 | 值 |
|---|---|
| serial | `<serial>` |
| `ro.product.device` | `lmipro` |
| `ro.product.model` | `Redmi_K30_Pro_Zoom_Edition` |
| `ro.product.mod_device` | `lmi` |
| `ro.product.product.name` | `miproduct_lmi` |
| Android | 16（SDK 36） |
| 构建 | `OS3.0.301.0.WJKCNXM`（HyperOS 3） |
| fingerprint | `Redmi/lmipro/lmipro:16/BP2A.250605.031.A3/OS3.0.301.0.WJKCNXM:user/release-keys` |
| first API level | 29（Android 10 出厂） |
| `ro.boot.slot_suffix` | 空（A-only） |
| `ro.boot.flash.locked` | 1（**属性误导，见 fastboot**） |
| `ro.boot.verifiedbootstate` | green（同上） |
| root | 无 `su`、无 Magisk/KernelSU/APatch |
| TWRP | 无（`ro.twrp.version` 为空） |
| 电量 | 82%，4019 mV，28.2°C，USB 供电 |
| userdata | 226G 总，167G 已用，59G 可用（`/data`） |
| 屏幕 | 1080×2400，60Hz，OLED，density 440 |
| 相机 | 主摄 IMX686，超广角 OV13B10，长焦 OV08A10（Zoom），前摄 S5K3T2，景深 GC02M1 |
| 指纹 | Goodix 屏下（`goodix_fod`） |

## 2. Fastboot 侧（权威）

| 项 | 值 |
|---|---|
| product | **lmi** |
| unlocked | **yes** |
| secure | yes |
| anti | 1 |
| hw-revision | 20001 |
| current-slot / has-slot | 变量不存在（A-only） |
| battery-voltage | 4019 mV |
| max-download-size | 768 MiB |

完整输出：`原始输出未上传；分区表见 03-device-audit.md`（257 行，含 116 个分区大小）。

## 3. 分区映射

| 名称 | 设备节点 | 大小 |
|---|---|---|
| boot | `/dev/block/sde50` | 128 MiB |
| dtbo | `/dev/block/sde47` | 32 MiB |
| recovery | `/dev/block/sda28` | 128 MiB |
| super | `/dev/block/sda32` | 0x220000000（约 8.5 GiB） |
| userdata | `/dev/block/sda34` | 0x388B7FB000（约 226 GiB） |
| vbmeta | `/dev/block/sde16` | 128 KiB |
| vbmeta_system | `/dev/block/sde17` | 128 KiB |
| vbmeta_vendor | `/dev/block/sde25` | 128 KiB |
| vbmeta_product | `/dev/block/sde26` | 128 KiB |
| vbmeta_odm | `/dev/block/sde27` | 128 KiB |
| metadata | `/dev/block/sda18` | 16 MiB |
| misc | `/dev/block/sda11` | 4 MiB |
| persist | `/dev/block/sda22` | 64 MiB |
| devinfo | `/dev/block/sda16` | 16 MiB |
| modem | `/dev/block/sde51` | 448 MiB |
| dsp | `/dev/block/sde49` | 64 MiB |
| bluetooth | `/dev/block/sde35` | 1 MiB |
| modemst1 / modemst2 | `/dev/block/sdf2` / `sdf3` | 2 MiB each |
| fsg | `/dev/block/sdf4` | 2 MiB |
| fsc | `/dev/block/sdf5` | 128 KiB |
| mdm1m9kefs1/2/3 | `/dev/block/sdf8` / `sdf9` / `sdf7` | 8 MiB each |

## 4. 与移植方案的关系

- `lmipro` 只是 Zoom 版的产品名；bootloader 报 `lmi`，平台属性也是 `lmi`，现有 `device-xiaomi-lmi` / `sm8250-xiaomi-lmi.dts` 适用。
- K30 Pro Zoom 多出的 OV08A10 长焦不在主线相机支持内；现有移植只做 OV13B10 超广角 raw + UVC，所以不影响“先跑起来”。
- A-only + 单 `boot` / `dtbo` / `recovery`；pmOS 的 boot image header v2 + 追加 DTB 方案匹配。
- `userdata` 是 226G，pmbootstrap 默认把 rootfs 写到这里；会清空 167G Android 数据。
- 设备唯一数据在 `persist`、`modemst1/2`、`fsg`、`fsc`、`devinfo` 等分区；即使只刷 boot/userdata，也建议先备份这些。
- 目前没有 root/TWRP，无法直接从 Android 读块设备；需要一个临时 root 环境（TWRP `fastboot boot` 或 pmOS initramfs）。

## 5. 待确认项（已在后续确认）

- [x] 面板具体型号：AMS667UU01（Linux 启动后确认）
- [x] 触控 IC：FT3518
- [x] 个人数据已备份（不在本仓库）
- [x] 临时 root 环境：TWRP + 离线镜像已完成分区备份
- [x] MIUI/HyperOS 线刷包版本：`OS3.0.301.0.WJKCNXM`（哈希未核对）
