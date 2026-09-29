# ImmortalWrt 24.10 x86_64 / 4GB RootFS / EFI 定制构建方案

目标：PVE -> RouterOS 主路由 -> ImmortalWrt 24.10 旁路由；IPv4-only；OpenClash 主用；Open-Box / PassWall / PassWall2 / Nikki / HomeProxy / MosDNS / SmartDNS 等作为备用工具，默认不启动，避免多个代理/DNS/TUN 服务互相抢占。

## 基线

- ImmortalWrt 24.10.6
- target: x86/64, generic, EFI
- rootfs: ext4, ROOTFS_PARTSIZE=4096 MiB
- OpenClash: v0.47.156
- Open-Box: 不烘焙固定版本，首次运行 `openbox-install-latest.sh` 时由上游官方安装器自行解析最新 release；安装后默认停用
- 默认不写入用户的机场订阅/token，避免把私人凭据烧进公开固件

## 预装代理/网络软件

默认编译进镜像：
- luci-app-openclash
- luci-app-passwall
- luci-app-passwall2
- luci-app-nikki + mihomo-meta
- luci-app-homeproxy + sing-box
- luci-app-mosdns + v2ray-geodata
- smartdns + luci-app-smartdns（若 24.10 官方 feed 提供该包）
- xray-core / sing-box / 常用网络诊断工具

这些服务均默认 disabled；真正运行时只让一个方案负责 DNS/TUN/透明代理。

## PVE 建议

虚拟磁盘建议 8~16GB，EFI 启动，VirtIO 网卡接 RouterOS LAN 所在虚拟交换网络。镜像本身预留 4GB rootfs，超过 rootfs 的磁盘空间可在后续扩展文件系统时使用。

## 构建

### GitHub Actions（推荐）
1. 新建自己的 GitHub 仓库，把整个目录上传。
2. Actions -> `Build ImmortalWrt 24.10 x86_64 4G EFI` -> Run workflow。
3. 可选 `install_daed=true` 来额外尝试编译/集成 daed；默认 false，以保持 24.10 基线稳定。
4. 成功后 artifact 会包含 EFI ext4 镜像、sha256 和 manifest。

### 本地 Debian/Ubuntu

执行：

```sh
chmod +x scripts/build.sh
scripts/build.sh
```

## 首次开机

1. 先从 PVE 控制台登录并设置 root 密码。
2. 不要同时启动 OpenClash、PassWall、PassWall2、Nikki、HomeProxy、MosDNS、SmartDNS、Open-Box。
3. 将你的 YAML 放入 `/etc/openclash/config/` 后，再按你的旁路由地址设置网络和 DNS 1053 链。
4. `files/etc/openclash/custom/openclash_custom_rules.list` 已预置 OKTV 相关 DIRECT：`hidns.vip`、`cmliussss.com`、`090227.xyz`，并精确包含 `tvbbox.pgjgr.eu.cc`。

## 安全说明

这套构建脚本不会修改 RouterOS、PVE 物理网卡或你的机场订阅凭据。第三方仓库版本会变化，GitHub Actions 是为了让构建失败时保留完整日志，而不是声称每次未来构建都一定成功。
