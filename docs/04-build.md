# 构建环境与补丁 — lmi postmarketOS

- 日期：2026-10-23
- 主机：WSL2 Ubuntu 26.04，8 核 / 9.7GB 内存 / 859GB 空闲
- 工作目录：`~`（WSL 内），Windows 侧记录在本项目 `docs/`

## 1. 仓库与版本

| 对象 | 路径 / 地址 | 版本 |
|---|---|---|
| pmbootstrap | `~/pmbootstrap` | 3.12.1，commit `ff954a6` |
| pmaports fork | `~/pmaports-lmi` | 分支 `nikroks/alioth`，commit `b6453d5` |
| 内核源码 | `~/Linux-redmi-k30pro-6.19-6.19` | 6.19.0-rc8（tarball 解压） |
| 内核 tarball | `~/linux-lmi.tar.gz` | 247MB，SHA512 `231642ab...a67a` |
| 设备包 | `device/testing/device-xiaomi-lmi` | `device-xiaomi-lmi` |
| 内核包 | `device/testing/linux-postmarketos-qcom-sm8250-lmi` | 包版本元数据 6.19.7，实际内核 release 以 `kernel.release` 为准 |
| 固件包 | `device/testing/firmware-xiaomi-lmi` | — |

## 2. pmbootstrap 配置

`~/.config/pmbootstrap_v3.cfg`：

```ini
[pmbootstrap]
aports = ~/pmaports-lmi
build_default_device_arch = True
boot_size = 512
ccache_size = 10G
device = xiaomi-lmi
extra_packages = none
hostname = lmi
is_default_channel = False
jobs = 6
locale = C.UTF-8
service_manager = openrc
ssh_keys = False
sudo_timer = False
timezone = Asia/Shanghai
ui = phosh
user = user
work = /root/.local/var/pmbootstrap

[providers]

[mirrors]
alpine = https://mirrors.tuna.tsinghua.edu.cn/alpine/
pmaports = https://mirror.postmarketos.org/postmarketos/
```

说明：

- `boot_size = 512` 是 pmbootstrap 3.12 的硬性下限；**lmi 实际 boot 分区只有 128MiB**，所以刷入前必须检查 `boot.img` 实际大小。
- pmaports 的 `upstream` remote 指向官方 GitLab，并创建了 `refs/remotes/upstream/main`（指向 fork HEAD），用于让 pmbootstrap 读取 `channels.cfg`。
- 以 root 运行 pmbootstrap 必须加 `--as-root`。
- 这里的 `locale = C.UTF-8` 只是构建时默认；设备运行期已改为 `zh_CN.UTF-8`，见 `06-runtime.md`。

## 3. 本地补丁

### 3.1 内核 APKBUILD：builddir

`../patches/0001-lmi-kernel-builddir.patch`

```diff
-builddir="$srcdir/linux-v6.19"
+builddir="$srcdir/Linux-redmi-k30pro-6.19-6.19"
```

原因：GitHub archive 解压后的顶层目录是 `Linux-redmi-k30pro-6.19-6.19`（仓库改过名）。

### 3.2 内核源码哈希 + 6.19 配置

`../patches/0002-lmi-kernel-config-hash.patch`

- 补上内核 tarball 的 SHA512（原 APKBUILD 只写了 config 的哈希）。
- 用内核源码自带的 `arch/arm64/configs/sm8250.config` 合并 `defconfig` 生成 9,013 行完整配置，替换 pmaports 里那份 6.13 旧配置。
- 生成命令（在 `~/Linux-redmi-k30pro-6.19-6.19`）：

```bash
make ARCH=arm64 O=.output defconfig
make ARCH=arm64 O=.output sm8250.config
```

- 关键选项已确认：`CONFIG_LOCALVERSION="-sm8250"`、`CONFIG_DRM_PANEL_SAMSUNG_AMS667UU01=y`、`CONFIG_TOUCHSCREEN_FOCALTECH_FTS=y`、`CONFIG_VIDEO_OV13B10=m`、`CONFIG_SND_SOC_TFA9872=m`、`CONFIG_ATH11K=m`、`CONFIG_ATH11K_PCI=m`。
- 新 config 和 tarball 哈希已写回 APKBUILD。

### 3.3 pmbootstrap strict 模式

`../patches/0003-pmbootstrap-lax-deps.patch`

```diff
-        pmb.build.packages(context, to_add, arch)
+        pmb.build.packages(context, to_add, arch, strict=False)
```

原因：pmbootstrap 3.12 的 strict 模式在构建 `abuild` 时需要先安装 `abuild`，形成自锁；让依赖安装走 lax 路径即可。

### 3.4 Alpine 镜像

默认 `cdn.alpinelinux.org` 在当前网络下极慢（20 分钟只装到 26/47）。已改为：

```
https://mirrors.tuna.tsinghua.edu.cn/alpine/
```

### 3.5 设备包：source_deviceinfo（已回退）

`../archive/device-source_deviceinfo/0004-device-source-deviceinfo.patch` 曾尝试在设备包里补装 `/usr/share/misc/source_deviceinfo`，但后续确认该文件实际由 `devicepkg-utils-0.3.3-r0` 提供。已用 `../archive/device-source_deviceinfo/0004-device-source-deviceinfo-revert.patch` 回退（`pkgrel=2`），当前 APKBUILD 不再包含这条 `install`。

### 3.6 firmware-xiaomi-lmi

`device-xiaomi-lmi-nonfree-firmware` 依赖本地 `firmware-xiaomi-lmi`，但 install 的自动构建队列没有包含它。已单独构建：

```bash
pmbootstrap --as-root build --arch aarch64 --lax firmware-xiaomi-lmi
```

固件 tarball 已预先下载并校验（SHA512 与 APKBUILD 一致）。

### 3.7 电量计 qcom_fg（已进内核包）

`../patches/0001-power-supply-wire-qcom-fg.patch` 把已有的 `drivers/power/supply/qcom_fg.c` 接入 Kconfig/Makefile；补丁已加入内核 APKBUILD 的 `source` 和 `sha512sums`，配置已加 `CONFIG_BATTERY_QCOM_FG=m`，`pkgrel` 升到 1。下次构建的内核包会自带 `qcom_fg.ko`；当前设备上的模块是手工安装的等价版本。详见 `06-runtime.md`。

### 3.8 设备包运行期默认值（pkgrel=6）

`device-xiaomi-lmi` 的 `depends` 已加入：

- `font-noto-cjk`、`musl-locales`、65 个 `*-lang` 翻译包
- `nftables`（pmOS base 的 `postmarketos-base-nftables-openrc` 负责把它加入 `default` runlevel）

设备包同时安装：

| 文件 | 作用 |
|---|---|
| `/usr/share/gmobile-lmi/xiaomi,lmi.json` | gmobile 的 lmi 面板数据（圆角 150，配合 300% 缩放） |
| `/etc/phosh/phoc.ini` | 内屏 `scale = 3` |
| `/etc/locale.conf` | `LANG=zh_CN.UTF-8` |
| `/etc/skel/.phoshdebug` | 会话级 `LANG`/`LANGUAGE`/`G_RESOURCE_OVERLAYS`（phosh-session 自带 hook） |
| `/etc/nftables.d/60_lmi.nft` | 放行 DHCP 客户端续租和 mDNS，配合 pmOS 默认防火墙 |

这些文件对**下一次镜像构建**生效；当前设备上已有等价的手工文件。重刷旧镜像不会带上它们。

### 3.9 通用镜像构建

通用镜像不得包含个人 Wi-Fi、SSH 密钥或用户文件。使用 `scripts/build-generic-image.sh`：

```sh
# Default password is 147147 for the standard test image; override if desired.
GENERIC_PASSWORD='147147' scripts/build-generic-image.sh
```

- 镜像启动到 Phosh，用户先登录，再在设置里连接 Wi-Fi；不要预置 `.nmconnection`。
- 不要写入 `authorized_keys`、个人家目录或调试用的 root 公钥。
- 发布前检查镜像里没有 `NetworkManager/system-connections/*.nmconnection` 的个人配置、没有 `/root/.ssh` 私钥、没有个人文件。

## 4. 构建命令

```bash
# 进入 WSL，切到 pmbootstrap
wsl.exe -u root -- bash -lc 'export HOME=~; cd ~/pmbootstrap; \
  python3 pmbootstrap.py --as-root build --arch aarch64 abuild'

# 完整镜像（首次用 --no-recommends：fork 里的 GNOME 基础包推荐了
# 已被 Alpine edge 移除的 gvfs-afp；核心 Phosh 不依赖它）
wsl.exe -u root -- bash -lc 'export HOME=~; cd ~/pmbootstrap; \
  python3 pmbootstrap.py --as-root install --no-recommends --password <password>'

# 导出 boot.img / rootfs
wsl.exe -u root -- bash -lc 'export HOME=~; cd ~/pmbootstrap; \
  python3 pmbootstrap.py --as-root export'
```

产物通常在：

```
/root/.local/var/pmbootstrap/packages/edge/aarch64/
/tmp/postmarketOS-export/boot.img
/tmp/postmarketOS-export/xiaomi-lmi.img
```

## 5. 刷入前检查

1. `boot.img` 实际大小必须 < 128MiB（lmi boot 分区大小）。
2. rootfs 镜像写入 `userdata`（会清空 Android 数据）。
3. 备份仍在 `<local-backups>/`，哈希清单 `manifest.txt`。
4. pmOS 现在写在 `recovery` 分区并从 recovery 启动；`boot` 里的 pmOS 镜像会被 AVB 拒绝。TWRP 只在 `<local-backups>/`，需要时重刷；不要再假设 recovery 里是 TWRP。
5. 个人数据已备份，HyperOS 3 线刷包在手（均不在本仓库）。

## 6. 已知限制

- pmOS 移植的内核元数据是 6.19.7，但实际源码是 6.19.0-rc8；首次启动以 `uname -r` 为准。
- 2026-10-24 更新：电池读数（`qcom_fg`）、中文 UI、状态栏圆角已修复，见 `06-runtime.md`。
- 2026-10-24：nftables 已恢复 `default` runlevel，新增 DHCP 续租/mDNS 放行；运行时 start/restart、SSH/ping/DNS 已验证，冷启动待验证。
- 私有快充（BQ2597x）、modem、GPS、指纹、振动、完整相机仍不可用。
- 调亮度花屏是 pmOS 社区移植的已知问题。
- 休眠/待机未完整验证。
