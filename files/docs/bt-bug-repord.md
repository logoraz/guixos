# Bug Report: MT7925 Bluetooth Regression in linux-libre 6.18.29+

## Summary

MediaTek MT7925 Bluetooth controller fails to initialize on `linux-libre`
versions 6.18.29 and later. Bluetooth works correctly on 6.18.28. Wi-Fi half
of the same chip (driver `mt7925e`) continues to work across all versions.

## Hardware

- **Laptop**: Framework 13 AMD (Ryzen AI 300 series)
- **Chip**: MediaTek MT7925 (Wi-Fi 7 / Bluetooth 5.4)
- **USB ID**: `0e8d:0717` (MediaTek Wireless_Device)
- **Drivers**: `mt7925e` (Wi-Fi), `btusb` + `btmtk` (Bluetooth)

## Symptoms

- `bluetoothctl show` reports `No default controller available`
- Kernel log shows `Bluetooth: hci0: Failed to send wmt func ctrl (-22)`
- `HW/SW Version: 0x00000000` (chip never returns its version)
- Wi-Fi half initializes correctly: `mt7925e: HW/SW Version: 0x8a108a10`
- No `firmware load failed` errors — firmware blobs are present and being
  read from `linux-firmware-20260410`
- Failure persists across reboots, module reloads, autosuspend disable,
  ASPM disable, and Bluetooth firmware version downgrades

## Regression Range (confirmed)

- **Working**: `linux-libre` 6.18.28 (Guix channel commit `5f65d3f998`)
- **Broken**: `linux-libre` 6.18.31 (Guix channel commit `e97d0696`)
- Untested middle versions: 6.18.29, 6.18.30

The regression is in `guix` (not `nonguix`) — specifically the
`linux-libre` package version bump. `nonguix`'s `corrupt-linux` inherits
from `linux-libre`, so the regression flows downstream automatically.

## Reproducer

Pin `guix` channel to `5f65d3f998bdee32a3aa9690962c6c8eeaaa8ae0` and BT
works. Pin to `e97d0696c01b54ebbe3274e60ceab968a221d75a` (or any descendant
that includes 6.18.31) and BT breaks. Same `nonguix` commit
(`5f2630e6...`) in both cases.

## Cross-distro Evidence

This is an upstream Linux kernel regression, not Guix-specific:

- **CachyOS**: <https://discuss.cachyos.org/t/no-bluetooth-under-kernel-7-1-0-rc3-with-mediatek-mt7925/29531>
  (Framework 13, MT7925, kernel 7.1.0-rc3, same error — posted one week ago)
- **CachyOS (Lenovo Yoga 7, MT7925 `0489:e111`)**:
  <https://discuss.cachyos.org/t/mediatek-mt7925-0489-e111-bluetooth-hci0-initializes-twice-but-bluetooth-wont-work-after-boot/22079>
- **Fedora**: <https://discussion.fedoraproject.org/t/bluetooth-mt7925-broken-in-kernel-6-19-12-on-thinkpad-t14-gen-6/188188>
- **Arch Linux**: <https://bbs.archlinux.org/viewtopic.php?id=313561>
- **Linux Mint** (includes DKMS workaround):
  <https://forums.linuxmint.com/viewtopic.php?t=455342>
- **Framework Community**:
  <https://community.frame.work/t/mt7925-wifi-driver-fixes-now-available-as-dkms-package/79777>

DKMS patches available at <https://github.com/zbowling/mt7925> and
<https://github.com/jeremyb31/bluetooth-6.14> — these are what users on
other distros are applying.

## Workarounds Tested

| Workaround | Result |
| --- | --- |
| `modprobe btusb enable_autosuspend=0` | No change |
| `modprobe mt7925e disable_aspm=1` | No change |
| `modprobe -r mt7925e btusb` reload sequence | No change |
| Force `btusb` bind via `/sys/bus/usb/drivers/btusb/new_id` | No change |
| Cold boot (full power drain, AC unplugged, power button hold) | Not retested after pinpointing kernel cause |
| Older `linux-firmware` (20260309 instead of 20260410) | Not the cause — same failure with new firmware on working 6.18.28 |
| Roll back to `linux-libre` 6.18.28 | **Works** |

## Action Items

### Short-term (mitigation for affected users)

- [ ] **Pin Guix to `5f65d3f998`** in `channels.scm` until upstream fix lands
- [ ] **Document in nonguix README** that MT7925 Bluetooth is broken on
      linux-libre ≥6.18.29; suggest pin or USB dongle workaround
- [ ] **USB Bluetooth dongle** (TP-Link UB500, RTL8761B) as immediate
      hardware workaround for users who cannot pin

### File upstream bug reports

- [ ] **Guix bug**: email `bug-guix@gnu.org` with this regression range and
      cross-distro evidence; cc maintainers of the linux-libre point
      release bumps if known
- [ ] **Linux Bluetooth ML**: `linux-bluetooth@vger.kernel.org` — this is
      where the actual fix has to land; cite the regression bisect range
      and `btmtk`/`btusb` files as the likely source
- [ ] **nonguix issue**: open at
      <https://gitlab.com/nonguix/nonguix/-/issues> — primarily to alert
      MT7925 users and document the pin workaround; cite issue #318 (related
      MediaTek BT/WiFi config issue) for cross-reference

### Local Guix configuration

- [x] **System reconfigure** with pinned channels via `guix time-machine`
- [x] **Home reconfigure** to align channels with system:
      ```bash
      guix time-machine -C ~/.config/guix/channels.scm -- \
          home reconfigure --allow-downgrades -L ~/.config/guixos/ \
          ~/.config/guixos/guixos/home/guixos-home.scm
      ```
- [x] **Resolved: module-form `channels.scm` requires `--unsafe-channel-evaluation`
      on Guix ≥ `36d431c051` (Feb 26 2026).** That commit introduced sandboxed
      channel-file evaluation with a strict whitelist (`%safe-channel-bindings`)
      that does not include `define-module` or `use-modules`. Module-form
      channel files were never officially supported — they worked incidentally
      because the pre-sandbox evaluator inherited the full Guile environment.
      Currently pinned to `5f65d3f998` (pre-sandbox), so `gop` works. Once the
      pin advances past `36d431c051`, the CLI aliases (`gop`, `gostm`, `gohtm`)
      will need `--unsafe-channel-evaluation` added — TODO block already in
      `bash.scm` with commented-out variants ready to swap in.

## Diagnostic Data

### Working state (linux-libre 6.18.28)

```
$ uname -r
6.18.28
$ bluetoothctl show
Controller XX:XX:XX:XX:XX:XX
        ...
```

### Broken state (linux-libre 6.18.31)

```
$ uname -r
6.18.31
$ bluetoothctl show
No default controller available
$ sudo dmesg | grep -i bluetooth
[    2.384  ] Bluetooth: Core ver 2.22
[    2.384  ] Bluetooth: HCI device and connection manager initialized
[    2.391  ] usbcore: registered new interface driver btusb
[    2.396  ] Bluetooth: hci0: HW/SW Version: 0x00000000, Build Time: 20260106153314
[    2.882  ] Bluetooth: hci0: Failed to send wmt func ctrl (-22)
[    2.882  ] Bluetooth: hci0: HCI Enhanced Setup Synchronous Connection command is advertised, but not supported.
```

### Channel pin (working)

```scheme
(define %nonguix-channel
  (channel
    (name 'nonguix)
    (url "https://gitlab.com/nonguix/nonguix.git")
    (branch "master")
    (commit "5f2630e69fbbe9e79c350a67545f0fef7e93e223")
    ...))

(define %guix-channel
  (channel
    (name 'guix)
    (url "https://codeberg.org/guix/guix.git")
    (branch "master")
    (commit "5f65d3f998bdee32a3aa9690962c6c8eeaaa8ae0")
    ...))
```
