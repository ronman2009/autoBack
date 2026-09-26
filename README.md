# autoBack

[![License: GPL-2.0](https://img.shields.io/badge/License-GPL%20v2-blue.svg)](COPYING)
[![Based on Timeshift](https://img.shields.io/badge/based%20on-Timeshift-3465a4)](https://github.com/linuxmint/timeshift)
[![Platform](https://img.shields.io/badge/platform-Linux%20btrfs-blue)](#requirements)

**System snapshot & restore with an integrated independent rescue system.**

autoBack is a **deep fork of [Timeshift](https://github.com/linuxmint/timeshift)**
(GPL-2.0-or-later). Everything Timeshift does for btrfs snapshot management works
here — plus the two things Timeshift will never do:

## What autoBack adds

### 1. Snapshots carry GRUB automatically

Every btrfs snapshot automatically includes a **consistent ESP archive**
(`@/.recovery/esp-<ts>.tar.gz`) taken *before* the snapshot is created —
so the bootloader (`grubx64.efi`) always travels with the system it belongs to.
Restoring a snapshot can never break the bootloader through version mismatch,
and deleting a snapshot cleans up its archive automatically.

### 2. Integrated Rescue System panel

One-click build and firmware installation of an **independent rescue system**
(EFISTUB UKI: kernel + musl busybox + btrfs-progs):

- Boots directly from UEFI — **no GRUB, no OS required**
- Restores the system from any snapshot even when GRUB and the OS are broken
- `--recover` self-heal mode for torn-down state

Toolbar → **Rescue System** → Build → Install → done.

## Requirements

- Linux with btrfs root (`@` subvolume layout, Timeshift btrfs mode compatible)
- UEFI boot, no disk encryption

## Build & Install

```bash
meson setup build -Dman=false
ninja -C build
sudo ninja -C build install
```

Rescue system build scripts (kernel pinning, UKI assembly, ESP install)
are expected under `/usr/share/autoback/rescue` — see the
[development kit](https://github.com/ronman2009/allAuto-rollBack-inBios).

## Credits

- **autoBack** maintained by [ronman2009](https://github.com/ronman2009)
- Based on **Timeshift** by [Tony George](https://github.com/teejeetech) / Linux Mint
- Rescue system design inspired by [ZFSBootMenu](https://zfsbootmenu.org)

## License

GPL-2.0-or-later (inherited from Timeshift)
