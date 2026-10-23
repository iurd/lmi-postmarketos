# 运行期配置与清理 — lmi（2026-10-24）

设备：Redmi K30 Pro Zoom（`lmi`），pmOS edge + Phosh 0.58，内核 `6.19.0-rc8-sm8250`，从 `recovery` 启动，root SSH over Wi-Fi。

## 已验证

- 中文界面：Phosh/GTK 及已安装应用显示中文；`locale -a` 含 `zh_CN`；`/usr/share/locale/zh_CN/LC_MESSAGES` 有 67 个 `.mo`。
- 状态栏：`scale=3`（300%）；左右图标按圆角内缩，设备上确认不再被 R 角遮挡。
- 电池：`qcom-battery` 出现在 UPower；示例读数 99%、4.43 V、30 °C、Charging。
- 电量计模块随开机加载：当前设备 `/etc/modules` 含 `qcom_fg`；新镜像里内核包安装模块后，udev 会按 `of:N*T*Cqcom,pm8150b-fg` 自动加载。

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

这些文件已经写入 pmaports：设备包 `device-xiaomi-lmi`（`pkgrel=5`）安装面板 JSON、`phoc.ini`、`locale.conf`、`.phoshdebug`、`60_lmi.nft` 和字体/语言依赖；内核包（`pkgrel=1`）带 `qcom_fg` 补丁和配置。当前设备上是等价的手工文件，下一次镜像构建会直接带上。

改语言/缩放/圆角后需要重新登录（重启 greetd 或注销）才生效。

## 已清理的旧尝试

- `phosh-session` 里的 `LD_PRELOAD=/usr/local/lib/libgmobile-radius.so`（旧 preload 方案，函数从未被调用）。
- `/usr/local/lib/libgmobile-radius.so`、`/tmp/gm-radius*`。
- `/home/user/.config/gtk-3.0/gtk.css`（旧 CSS 内边距方案，Phosh 0.58 不生效）。
- `/usr/bin/phosh-session.bak`、`/root/phosh-session.pre-lmi`。
- 调试用 `G_MESSAGES_DEBUG=phosh-layout-manager`（已从配置文件删除）。
- `grim`（Phoc 不提供 wlr-screencopy，截图不可用）及 `/tmp` 临时文件。
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
```

如果已经安装了新的 `device-xiaomi-lmi` r4，`apk del` 这些依赖会被包依赖阻止；需要先降级/删除设备包，或直接用 `apk del --force` 并接受设备包处于不满足依赖的状态。

## nftables（已修复）

- 2026-10-23 离线镜像阶段移除了 runlevel 链接；2026-10-24 已恢复：
  - 默认规则集 `/etc/nftables.nft` 加上 `/etc/nftables.d/` 的 pmOS drop-ins，其中已有 `50_sshd.nft` 放行 TCP 22。
  - 新增 `/etc/nftables.d/60_lmi.nft`：放行 DHCP 客户端续租（`udp sport 67 dport 68`）和 mDNS（`udp dport 5353`）。
  - `rc-service nftables start` / `restart` 均通过；SSH、ping 网关、DNS 解析正常。
  - 已执行 `rc-update add nftables default`；pmOS base 本身也会在安装时启用该服务。
- 当前策略：input/forward 默认 drop，output accept；loopback、established/related、ICMP、SSH、DHCP、mDNS、localsend、AusweisApp2、USB/hotspot 已放行。
- 注意：这会在下次冷启动生效；本次只验证了运行时 start/restart，未重启设备做冷启动验证。

## 技术债

| 项 | 现状 | 影响 | 退出条件 |
|---|---|---|---|
| 圆角半径 150 是为 300% 缩放调的值 | 不是实测硬件半径（估计约 100） | 改缩放/分辨率后可能偏紧或偏松 | 用面板实测半径或 EDID/DT 数据；上游支持真实圆角 |
| 无截图/视觉自动化 | Phoc 无 wlr-screencopy；Shell Screenshot D-Bus 返回 false | 只能靠人眼确认 UI | 使用支持 screencopy 的合成器/插件，或修 Phoc 截图 |
| 无中文输入法 | squeekboard 无拼音布局 | 只能显示中文，不能输入中文 | 接 fcitx5 + Wayland input-method（需 Phoc/Phosh 支持） |

## 构建产物与重建

- 模块：`out/qcom_fg-6.19.0-rc8-sm8250.ko`
- 内核补丁：`../patches/0001-power-supply-wire-qcom-fg.patch`；已加入 pmaports 内核包 `source` 和 `sha512sums`，配置已加 `CONFIG_BATTERY_QCOM_FG=m`
- 设备包文件：pmaports `device/testing/device-xiaomi-lmi/` 下的 `xiaomi,lmi.json`、`phoc.ini`、`locale.conf`、`phoshdebug`、`60_lmi.nft`；依赖里已加字体/语言包
- 运行配置副本：`../runtime/{xiaomi,lmi.json,phoshdebug,phoc.ini,60_lmi.nft}`
- 运行内核配置：`../patches/config-6.19.0-rc8-sm8250-running`
- 本次构建验证：`../verification/build-2026-10-24.md`（内核 r1、设备 r4、`qcom_fg.ko` vermagic）

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
