# autoBack

[![License: GPL-2.0](https://img.shields.io/badge/License-GPL%20v2-blue.svg)](COPYING)
[![Based on Timeshift](https://img.shields.io/badge/based%20on-Timeshift-3465a4)](https://github.com/linuxmint/timeshift)
[![Platform](https://img.shields.io/badge/platform-Linux%20btrfs-blue)](#%E5%BF%AB%E9%80%9F%E5%BC%80%E5%A7%8B)

**系统快照与还原，内置独立救援系统——GRUB 和主系统全坏了也能从固件恢复。**

autoBack 是 [Timeshift](https://github.com/linuxmint/timeshift)（GPL-2.0-or-later）
的深度改装版。Timeshift 的全部 btrfs 快照管理能力照常工作，另外补上了
Timeshift 永远不会做的两件事。

## 这解决什么问题

Timeshift 能回滚系统，但它自己活在主系统里；GRUB 负责引导，却也是最容易坏的环节。
主系统起不来的时候，Timeshift 无能为力——而且回滚后 GRUB 与 `/boot/grub`
的版本错配甚至可能让回滚本身毁掉系统。

| 场景 | Timeshift | autoBack |
|---|---|---|
| 系统正常，日常回滚 | ✅ 主场 | ✅ 同样能力 |
| **GRUB / 内核 / 主系统全挂** | ❌ 它自己就活在主系统里 | ✅ 固件直引，唯一手段 |
| GRUB 版本与 /boot/grub 错配 | ❌ 无处理 | ✅ 每个快照自动携带 ESP 归档 |
| 删除快照的清理 | ✅ | ✅ 归档随快照自动一并删除 |

## autoBack 加了什么

### 1. 快照自动携带 GRUB

每次创建 btrfs 快照**之前**，ESP（含 `grubx64.efi`）会先被打包进
`@/.recovery/esp-<ts>.tar.gz`——归档与快照原子锁定在同一时刻。
回滚到哪个时刻，引导器就是哪个时刻的版本，杜绝版本错配毁系统。

### 2. 内置救援系统面板

主窗口工具栏 **Rescue System** 一键构建并安装独立救援系统
（EFISTUB UKI：内核 + musl busybox + btrfs-progs）：

- 直接从 UEFI 固件引导——**不需要 GRUB，不需要主系统**
- 主系统全挂时从任意快照还原，支持 `--recover` 拆解态自愈
- 构建日志内嵌显示，状态自检一键完成

## 快速开始

**前提**：Linux + btrfs 根分区（`@` 子卷布局，兼容 Timeshift btrfs 模式）、UEFI 启动。

```bash
meson setup build -Dman=false
ninja -C build
sudo ninja -C build install
```

救援系统构建脚本（内核钉入、UKI 组装、ESP 安装）需安装到
`/usr/share/autoback/rescue`——见
[开发套件仓库 allAuto-rollBack-inBios](https://github.com/ronman2009/allAuto-rollBack-inBios)。

## 边界

- ⚠️ 不保护用户数据：`@home` 默认排除（与 Timeshift 相同）
- ⚠️ 救援内核版本与镜像写死：主系统升级内核后需重新构建
- ⚠️ 不承诺硬件级灾难：固件损坏、磁盘故障无解
- 🔄 仅支持 btrfs 模式，不支持 rsync 模式

## 致谢

- **autoBack** 由 [ronman2009](https://github.com/ronman2009) 维护
- 基于 **Timeshift**（[Tony George](https://github.com/teejeetech) / Linux Mint）深度改装
- 救援系统设计灵感来自 [ZFSBootMenu](https://zfsbootmenu.org)

## 许可证

GPL-2.0-or-later（继承自 Timeshift，衍生作品依法沿用）
