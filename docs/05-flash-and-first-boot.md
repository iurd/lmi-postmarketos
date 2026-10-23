# 刷入与首启记录 — lmi postmarketOS

- 设备：K30 Pro Zoom（`lmipro` 产品名，bootloader `lmi`），A-only，`unlocked: yes`
- 前提：`boot`/`userdata` 备份已完成并校验；个人数据已备份；HyperOS 线刷包在手
- 原计划只写 `boot` + `userdata`；实际执行有偏差，见第 3 节

## 1. 构建产物

`pmbootstrap install` 完成后：

```bash
# 在 WSL 内
export HOME=~
cd ~/pmbootstrap
python3 pmbootstrap.py --as-root export
```

产物：

```
/tmp/postmarketOS-export/boot.img
/tmp/postmarketOS-export/xiaomi-lmi.img
```

已复制到：

```
.\out\
```

本次使用的 `boot.img` SHA256：

```
7ba239d91b5e195df4fdd069a4dd14d579fa2d07da6e182599f158d55fb51ffc
```

设备内 `/boot/boot.img` 与 `out/boot.img` 哈希一致；内核 `uname -r` = `6.19.0-rc8-sm8250`。

## 2. 刷入前硬性检查

1. `boot.img` 必须 **< 128 MiB**（`boot` 分区大小 0x8000000）。
2. `boot.img` 的 DTB 字段包含 `sm8250-xiaomi-lmi.dtb`；`deviceinfo_append_dtb=true`。
3. `xiaomi-lmi.img` 大小应远小于 userdata（226 GiB 可用）。
4. 设备电量 ≥ 50%；本次执行时约 82%。
5. 备份仍在 `<local-backups>/`，哈希清单 `manifest.txt`。
6. serial 固定为 `<serial>`，每条命令带 `-s`。

## 3. 实际刷入

先按原计划写入 `boot` + `userdata`：

```bash
adb -s <serial> reboot bootloader
fastboot devices
fastboot -s <serial> flash boot out/boot.img
fastboot -s <serial> flash userdata out/xiaomi-lmi.img
fastboot -s <serial> reboot
```

结果：两个分区都写入成功，但 **bootloader 以 AVB 为由拒绝启动 `boot` 里的 pmOS 镜像**，重启落回 fastboot。

实际生效的启动路径：

```bash
fastboot -s <serial> flash recovery out/boot.img
fastboot -s <serial> reboot recovery
```

- 同一份 `boot.img` 刷到 `recovery` 后可以被接受，pmOS 从 recovery 启动。
- rootfs 仍在 `userdata`（镜像内的嵌套分区）。
- `boot` 分区目前仍是被拒绝的 pmOS 镜像；正常重启会回到 fastboot。
- TWRP 不在 recovery 里了，需要时从 `<local-backups>/` 重刷。

## 4. 首启实际观察

1. 屏幕：直接进入 Phosh 锁屏/登录（安装时已设置 `user` / `<password>`），没有走完整首启向导。
2. 显示/触摸/OSK 正常；日志无致命错误。
3. USB 枚举为 `VID_18D1&PID_D001` / `POSTMARKETOS`，但**没有 adbd**；USB 网络未验证。
4. 早期调试镜像曾预置 root 公钥和 Wi-Fi；**通用镜像不包含任何 Wi-Fi 凭据、SSH 公钥或私钥**。需要 SSH 时请登录后自行配置。
5. 锁屏不能选择 SSID；先登录（默认账户），再在设置里连接 Wi-Fi。通用构建不会自动连接任何网络。
6. 早期 `--no-recommends` 镜像漏掉了 OSK/SSH，后来离线补装 `squeekboard` 和 `openssh-server`；通用镜像使用 Phosh 默认的 `stevia`，并且不默认启用 SSH。
7. 2026-10-24 已补：中文界面、状态栏圆角补偿、PM8150B 电池读数，见 `06-runtime.md`。

## 5. 回退 Android

当前 `boot` 分区是会被 AVB 拒绝的 pmOS 镜像，回退时刷回备份的 Android boot。pmOS 里没有 adbd，从设备侧重启 bootloader 用 SSH：

```bash
ssh root@<设备IP> reboot bootloader
fastboot -s <serial> flash boot <local-backups>/boot.img
fastboot -s <serial> reboot
```

- 若还要 TWRP，再从备份重刷 `recovery.img`。
- Android 数据已被清空；要恢复 Android 系统/数据，用 HyperOS 3 线刷包 + 用户自己的数据备份。
- TWRP 可用于恢复 `persist`/`modemst` 等（非必要不要写）。

## 6. 首启验收清单

- [x] 能看到 pmOS/Phosh 画面
- [x] 触摸可用
- [x] SSH 可用（Wi-Fi + root key；USB 网络未验证、无 adbd）
- [x] Wi-Fi 可连接
- [ ] 蓝牙可开关（未复验）
- [ ] 扬声器/听筒/麦克风（未验收）
- [x] 电量/充电读数正常（`qcom_fg`，2026-10-24）
- [ ] 冷启动（当前只能从 recovery 启动；普通重启回 fastboot，AVB 未解决）
- [x] 记录 `boot.img` SHA256、`uname -r`（见第 1 节）
- [x] 中文界面（2026-10-24）
- [x] 状态栏左右图标避开 R 角（2026-10-24）
- [x] 电池图标/百分比显示（2026-10-24）
