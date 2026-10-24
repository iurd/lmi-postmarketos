# 运行期配置与清理 — lmi（2026-10-24）

设备：Redmi K30 Pro Zoom（`lmi`），pmOS edge + Phosh 0.58，内核 `6.19.0-rc8-sm8250`，从 `recovery` 启动，root SSH over Wi-Fi。

> 隐私说明：调试用个人 Wi-Fi 配置和 root SSH 密钥已在验证后从设备删除；本仓库和通用构建脚本不包含它们。

## 已验证

- 中文界面：Phosh/GTK 及已安装应用显示中文；`locale -a` 含 `zh_CN`；`/usr/share/locale/zh_CN/LC_MESSAGES` 有 67 个 `.mo`。
- 状态栏：`scale=3`（300%）；左右图标按圆角内缩，设备上确认不再被 R 角遮挡。
- 电池：`qcom-battery` 出现在 UPower；示例读数 99%、4.43 V、30 °C、Charging。
- 电量计模块随开机加载：当前设备 `/etc/modules` 含 `qcom_fg`；新镜像里内核包安装模块后，udev 会按 `of:N*T*Cqcom,pm8150b-fg` 自动加载。
- 扬声器：PulseAudio `HiFi` profile，`alsa_output.platform-sound.HiFi__Speaker__sink`，1 kHz 测试音可听。
- 麦克风：`alsa_input.platform-sound.HiFi__Mic1__source`，`parecord` rc=0；ADC1 增益 12（+18 dB）；安静环境峰值约 2291、RMS 82，无削波。
- 中文输入：fcitx5 原生 Wayland + pinyin，`fcitx5-remote -n` 返回 `pinyin`；GTK 应用可直接输入中文。
- 截图：`grim /tmp/shot.png` 成功（103 KB PNG），旧文档中“Phoc 无 screencopy”的说法已过时。

## 设备上的改动

| 路径 | 作用 | 回退 |
|---|---|---|
| `/usr/share/gmobile-lmi/xiaomi,lmi.json` | 给 gmobile 提供 lmi 面板数据（1080×2400，圆角 150） | 删除文件，并从 `.phoshdebug` 去掉 `G_RESOURCE_OVERLAYS` |
| `/home/user/.phoshdebug`（镜像里是 `/etc/skel/.phoshdebug`） | 通过 phosh-session 自带 hook 注入语言和 `G_RESOURCE_OVERLAYS` | 删除文件 |
| `/usr/bin/phosh-session` | 已恢复发行版原版，不再打补丁 | 无需回退 |
| `/etc/phosh/phoc.ini` | 固定内屏 300% 缩放 | 删除该文件或改回之前的 `scale = 2` |
| `/etc/locale.conf` | 系统默认语言 `zh_CN.UTF-8` | 改回 `C.UTF-8` |
| `/etc/modules` + `/lib/modules/.../qcom_fg.ko` | 开机加载 PM8150B 电量计 | `rmmod qcom_fg`；删 `/etc/modules` 条目和模块后 `depmod -a` |
| `font-noto-cjk`、`musl-locales`、65 个 `*-lang` 包 | 中文字体、locale 数据、翻译 | `apk del` 对应包 |
| `/etc/nftables.d/60_lmi.nft` + `nftables` runlevel | DHCP 续租/mDNS 放行，防火墙开机启动 | `rc-update del nftables default`；`rc-service nftables stop`；删 drop-in |
| `/usr/share/alsa/ucm2/Xiaomi/lmi/{lmi,HiFi}.conf` + `conf.d/sm8250`、`conf.d/snd-sm8250`、`conf.virt.d` 软链 | 让 ALSA/PulseAudio 找到 lmi 的扬声器和 Mic1 路由 | 删除目录和软链 |
| `/usr/bin/fcitx5-session-start`、`/etc/xdg/autostart/fcitx5.desktop`、`/etc/skel/.config/fcitx5/profile` | 登录后启动 fcitx5 并切到 pinyin，带 10 次重试 | `apk del fcitx5 fcitx5-chinese-addons fcitx5-gtk`；删除文件 |
| `.phoshdebug` 中的 `unset GTK_IM_MODULE QT_IM_MODULE` 和 `XMODIFIERS=@im=fcitx` | 让 GTK 应用走 Wayland input-method，而不是找 IBus | 删除对应行 |

这些文件已经写入 pmaports：设备包 `device-xiaomi-lmi`（`pkgrel=12`）安装面板 JSON、`phoc.ini`、`locale.conf`、`.phoshdebug`、UCM、fcitx5 运行文件和 `60_lmi.nft`；内核包（`pkgrel=3`）带 `qcom_fg` 补丁、声卡改名补丁和配置。当前设备安装的就是 r12/r3 包。

改语言/缩放/圆角后需要重新登录（重启 greetd 或注销）才生效。

## 已清理的旧尝试

- `phosh-session` 里的 `LD_PRELOAD=/usr/local/lib/libgmobile-radius.so`（旧 preload 方案，函数从未被调用）。
- `/usr/local/lib/libgmobile-radius.so`、`/tmp/gm-radius*`。
- `/home/user/.config/gtk-3.0/gtk.css`（旧 CSS 内边距方案，Phosh 0.58 不生效）。
- `/usr/bin/phosh-session.bak`、`/root/phosh-session.pre-lmi`。
- 调试用 `G_MESSAGES_DEBUG=phosh-layout-manager`（已从配置文件删除）。
- 早期曾卸载 `grim`（当时认为 Phoc 不提供 wlr-screencopy）；2026-10-24 复核发现当前 Phoc 已支持，已重新安装并验证 `grim /tmp/shot.png` 可用。
- `/etc/phosh/session-env` 和 `phosh-session` 的一行注入（改用上游 `.phoshdebug` hook，`phosh-session` 已恢复原版）。

## 回退整组改动

```sh
# 中文 + 圆角（当前用户和后续新用户）
rm -f /home/user/.phoshdebug /etc/skel/.phoshdebug
rm -f /usr/share/gmobile-lmi/xiaomi,lmi.json
echo LANG=C.UTF-8 > /etc/locale.conf
apk del font-noto-cjk musl-locales $(grep -E -- '-lang$' /etc/apk/world | tr '\n' ' ')

# 缩放
rm -f /etc/phosh/phoc.ini

# 电池
rmmod qcom_fg 2>/dev/null
sed -i '/^qcom_fg$/d' /etc/modules
rm -f /lib/modules/6.19.0-rc8-sm8250/kernel/drivers/power/supply/qcom_fg.ko
depmod -a

# nftables
rc-update del nftables default
rc-service nftables stop
rm -f /etc/nftables.d/60_lmi.nft

# 中文输入
apk del fcitx5 fcitx5-chinese-addons fcitx5-gtk
rm -f /usr/bin/fcitx5-session-start /etc/xdg/autostart/fcitx5.desktop \
      /etc/skel/.config/fcitx5/profile

# UCM / 麦克风路由
rm -rf /usr/share/alsa/ucm2/Xiaomi/lmi
rm -f /usr/share/alsa/ucm2/conf.d/sm8250/{lmi,Xiaomi-lmi,sm8250,snd-sm8250}.conf \
      /usr/share/alsa/ucm2/conf.d/snd-sm8250/{lmi,Xiaomi-lmi,sm8250,snd-sm8250}.conf \
      /usr/share/alsa/ucm2/conf.virt.d/{lmi,Xiaomi-lmi}.conf
```

如果已经安装了新的 `device-xiaomi-lmi` r12，`apk del` 这些依赖会被包依赖阻止；需要先降级/删除设备包，或直接用 `apk del --force` 并接受设备包处于不满足依赖的状态。

## nftables（已修复）

- 2026-10-23 离线镜像阶段移除了 runlevel 链接；2026-10-24 已恢复：
  - 默认规则集 `/etc/nftables.nft` 加上 `/etc/nftables.d/` 的 pmOS drop-ins，其中已有 `50_sshd.nft` 放行 TCP 22。
  - 新增 `/etc/nftables.d/60_lmi.nft`：放行 DHCP 客户端续租（`udp sport 67 dport 68`）和 mDNS（`udp dport 5353`）。
  - `rc-service nftables start` / `restart` 均通过；SSH、ping 网关、DNS 解析正常。
  - 已执行 `rc-update add nftables default`；pmOS base 本身也会在安装时启用该服务。
- 当前策略：input/forward 默认 drop，output accept；loopback、established/related、ICMP、SSH、DHCP、mDNS、localsend、AusweisApp2、USB/hotspot 已放行。
- 注意：这会在下次冷启动生效；本次只验证了运行时 start/restart，未重启设备做冷启动验证。

## 音频 / 麦克风（已修复）

- 声卡：`card 0: lmi [lmi]`，驱动 `sm8250` → `snd-sm8250`；`/proc/asound/cards` 名称是 `lmi`。DTS 里 `sound.model` 原来是 `"Xiaomi lmi"`，带空格的名称会让 PulseAudio/ALSA 的 `snd_use_case_mgr_open()` 找不到 UCM，内核包补丁 `0002-arm64-dts-qcom-sm8250-lmi-rename-sound-card.patch` 改为 `"lmi"`。
- UCM：文件安装到 `/usr/share/alsa/ucm2/Xiaomi/lmi/`，并在 `conf.d/sm8250/`、`conf.d/snd-sm8250/`、`conf.virt.d/` 下为 `lmi`/`Xiaomi-lmi`/`sm8250`/`snd-sm8250` 建软链。序列里用 `cdev "hw:0"`，不要用未定义的 `${CardId}`。
- 扬声器：`PRI_MI2S_RX Audio Mixer MultiMedia1=1`、`RX_CODEC_DMA_RX_0 Audio Mixer MultiMedia2=1`；PA sink `alsa_output.platform-sound.HiFi__Speaker__sink`。
- 麦克风：`MultiMedia3 Mixer TX_CODEC_DMA_TX_3=1`、`TX DEC0 MUX=SWR_MIC`、`TX SMIC MUX0=1`（枚举索引 1 = ADC0 → `TX SWR_ADC0` → codec ADC1）、`TX_AIF1_CAP Mixer DEC0=1`、`ADC1_MIXER Switch=1`、`ADC1 Switch=1`、`ADC1 Volume=12`；`CapturePCM "hw:0,2"`。
- 控件名必须是 raw 名：`ADC1_MIXER` 不存在，实际是 `ADC1_MIXER Switch`；`ADC1` 是 `ADC1 Switch` + `ADC1 Volume` 两个控件。
- 增益：ADC1 Volume 20（+30 dB）会削波（peak 32768）；12（+18 dB）合适。PA source 50% 时对应约 7/10 硬件增益。
- DSP：改完路由后必须**整机重启**。`card unbind/bind` 会让 WCD938x ADC 控件消失并残留 `q6adm cmd=0x10325 error=0x2`；冷启动后这些错误消失，采集正常。详见 `../verification/q6routing-reload-2026-10-24.md`。

## 中文输入（fcitx5）

- 方案：fcitx5 原生 Wayland input-method，不使用 IBus（IBus 引擎/GTK 模块在 Phosh 下抢不到输入焦点）。
- 包：`fcitx5`、`fcitx5-chinese-addons`、`fcitx5-gtk`。
- 文件：`/usr/bin/fcitx5-session-start`（`fcitx5 -d --replace` + 重试 `fcitx5-remote -s pinyin`）、`/etc/xdg/autostart/fcitx5.desktop`、`/etc/skel/.config/fcitx5/profile`（DefaultIM=pinyin）。
- 环境：`.phoshdebug` 里 `unset GTK_IM_MODULE QT_IM_MODULE`，并设 `XMODIFIERS=@im=fcitx`。
- 顺序很重要：先停 fcitx5，再写 profile，再启动；否则 profile 会被运行中的实例覆盖回 `keyboard-us`。
- 验证：`fcitx5-remote -n` 返回 `pinyin`。注意从 SSH 执行时要带上桌面会话的 `DBUS_SESSION_BUS_ADDRESS`（phoc 用 `dbus-run-session` 起了私有总线，路径在 `/proc/<phoc-pid>/environ`）。
- 已知残留：当前 phosh 会话里仍有 `QT_IM_MODULE=ibus`（来自发行版环境），Qt 应用可能仍走 IBus；GTK 应用正常。

## 技术债

| 项 | 现状 | 影响 | 退出条件 |
|---|---|---|---|
| 圆角半径 150 是为 300% 缩放调的值 | 不是实测硬件半径（估计约 100） | 改缩放/分辨率后可能偏紧或偏松 | 用面板实测半径或 EDID/DT 数据；上游支持真实圆角 |
| Qt 输入法环境残留 | 会话里仍有 `QT_IM_MODULE=ibus` | Qt 应用的中文输入可能失败 | 在 phosh 会话启动环境里显式 unset，或给 Qt 应用设 `QT_IM_MODULE=fcitx` |
| 截图只能手动执行 | `grim` 可用，但 Phosh Shell 的 Screenshot D-Bus 仍返回 false | 无法用系统截图 UI | 接 Phosh 截图接口或包一层 grim 脚本 |

## 构建产物与重建

- 模块：`out/qcom_fg-6.19.0-rc8-sm8250.ko`
- 内核补丁：`../patches/0001-power-supply-wire-qcom-fg.patch`（qcom_fg 接线）、`packages/linux-postmarketos-qcom-sm8250-lmi/0002-arm64-dts-qcom-sm8250-lmi-rename-sound-card.patch`（声卡改名 `lmi`）；均已加入 pmaports 内核包 `source`/`sha512sums`，配置含 `CONFIG_BATTERY_QCOM_FG=m`
- 设备包文件：pmaports `device/testing/device-xiaomi-lmi/` 下的 `xiaomi,lmi.json`、`phoc.ini`、`locale.conf`、`phoshdebug`、`60_lmi.nft`、`alsa-ucm-conf/`、`fcitx5-*`；依赖里已加字体/语言、fcitx5 和 nftables
- 运行配置副本：`../runtime/{xiaomi,lmi.json,phoshdebug,phoc.ini,60_lmi.nft,fcitx5-*}`
- 运行内核配置：`../patches/config-6.19.0-rc8-sm8250-running`
- 当前构建验证：`../verification/build-2026-10-24.md`（内核 r1/r3、设备 r4–r12、`qcom_fg.ko` vermagic）；音频/输入法见 `../verification/runtime-2026-10-24-audio-mic-ime.md`；boot 镜像见 [v0.2.0 release](https://github.com/iurd/lmi-postmarketos/releases/tag/v0.2.0-lmi)
- 增量构建耗时：设备包秒级；内核包在 ccache 命中时约 2 分钟，冷缓存约 1 小时

重建两个包：

```sh
export HOME=~
cd ~/pmbootstrap
python3 pmbootstrap.py --as-root build --arch aarch64 \
    linux-postmarketos-qcom-sm8250-lmi device-xiaomi-lmi
```

重建模块（只更新当前设备的手工模块；WSL 已装 `gcc-aarch64-linux-gnu`）：

```sh
SRC=~/Linux-redmi-k30pro-6.19-6.19
OUT=~/lmi-kbuild
cp ../patches/config-6.19.0-rc8-sm8250-running "$OUT/.config"
make -C "$SRC" O="$OUT" ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- olddefconfig
"$SRC/scripts/config" --file "$OUT/.config" -m BATTERY_QCOM_FG
make -C "$SRC" O="$OUT" ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- olddefconfig prepare modules_prepare
make -C "$SRC" O="$OUT" ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j8 \
     KBUILD_MODPOST_WARN=1 drivers/power/supply/qcom_fg.ko
```

安装前确认 `modinfo qcom_fg.ko` 的 `vermagic` 与 `uname -r` 一致；运行内核未开 `CONFIG_MODVERSIONS`，不需要 Module.symvers。
