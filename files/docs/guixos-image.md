# GuixOS Image and Install

## What we are doing

Build a preinstalled GuixOS disk image from this repo, write it to a USB
stick, boot a new machine from it, and use that running system to install
GuixOS onto the machine's internal disk.

The image contains the system only. The home configuration is applied
afterwards, once the machine is running.

## How it works

- `guixos/system/image.scm` takes `(host-operating-system)` from the chosen
  host and turns it into a bootable disk image.
- `guixos/host.scm` selects the host. Set it to the machine you are building
  for, for example `framework-pro`.
- Host file systems are found by label, not by UUID, so nothing has to be
  copied from `blkid`. `framework-pro.scm` expects the labels `EFI`, `swap`
  and `guixos`.
- `guix system init` installs the system onto the internal disk. Home is
  applied separately with `guix home reconfigure`.

## Part A: build and write the image (on `framework`)

### 1. Select the host

In `guixos/host.scm`, import the host module for the new machine:

```scheme
(guixos system hosts framework-pro)
```

### 2. Build the image

```
IMG=$(guix system image -L ~/Work/guixos \
  ~/Work/guixos/guixos/system/image.scm)
echo "$IMG"
```

The last line printed is the store path of the image.

### 3. Find the USB device

```
lsblk
```

Pick the stick by size, and make sure it is not a disk you use.

### 4. Write the image

```
sudo dd if="$IMG" of=/dev/sdX bs=4M status=progress conv=fsync
```

Replace `/dev/sdX` with the stick. This erases it. Then unmount it:

```
udiskie-umount /run/media/$USER/Guix_image
```

### 5. Grow the root partition

Plug the stick back in. The image root is small; grow it to fill the stick
so there is room for the pull and the install:

```
sudo parted /dev/sdX resizepart 2 100%
sudo e2fsck -f /dev/sdX2
sudo resize2fs /dev/sdX2
```

## Part B: boot the stick (on `framework-pro`)

### 6. Disable Secure Boot

Press F2 at power-on, open the BIOS, choose Administer Secure Boot, and
disable it.

### 7. Boot the stick

Press F12 at power-on and choose the USB device.

### 8. Set a first-login password

Guix creates the accounts on first boot with a locked password. Let the
machine reach the greeter once so `/etc/shadow` exists, power off, then
mount the stick's root from another Guix machine and set a throwaway hash:

```
sudo mount /dev/sdX2 /mnt
set +H
HASH=$(openssl passwd -6 changeme)
sudo sed -i "s|^USER:!:|USER:${HASH}:|" /mnt/etc/shadow
```

Replace `USER` with the account name. Boot the stick, log in with
`changeme`, and run `passwd`.

### 9. Connect to wifi

```
sudo nmcli device wifi connect 'SSID' password 'PASSWORD'
```

### 10. Put the repo in place

`config-source` expects the repo at `~/.config/guixos`. Keep the repo in
`~/Work/guixos` and link it:

```
mkdir -p ~/Work ~/.config
git clone https://github.com/logoraz/guixos ~/Work/guixos
ln -s ~/Work/guixos ~/.config/guixos
```

### 11. Pull with the pinned channels

```
guix pull -C ~/.config/guixos/guixos/system/channels.scm
```

The pulled Guix is `~/.config/guix/current/bin/guix`. Use it for everything
below; it includes nonguix.

## Part C: install onto the internal disk

### 12. Partition

GPT, with three partitions on the internal NVMe:

| Partition   | Size   | Type       | Label    |
|-------------|--------|------------|----------|
| `nvme0n1p1` | 1 GiB  | EFI system | `EFI`    |
| `nvme0n1p2` | 64 GiB | swap       | `swap`   |
| `nvme0n1p3` | rest   | btrfs      | `guixos` |

```
sudo sfdisk /dev/nvme0n1 <<EOF
label: gpt
size=1GiB, type=U
size=64GiB, type=S
type=L
EOF
```

### 13. Format

```
sudo mkfs.vfat -F32 -n EFI /dev/nvme0n1p1
sudo mkswap -L swap /dev/nvme0n1p2
sudo mkfs.btrfs -L guixos /dev/nvme0n1p3
```

### 14. Create the btrfs subvolumes

```
sudo mount /dev/nvme0n1p3 /mnt
sudo btrfs subvolume create /mnt/@
sudo btrfs subvolume create /mnt/@home
sudo umount /mnt
```

### 15. Mount

```
sudo mount -o subvol=@,compress=zstd,noatime /dev/nvme0n1p3 /mnt
sudo mkdir -p /mnt/home /mnt/boot/efi
sudo mount -o subvol=@home,compress=zstd,noatime /dev/nvme0n1p3 /mnt/home
sudo mount /dev/nvme0n1p1 /mnt/boot/efi
findmnt -R /mnt
```

### 16. Install

```
sudo ~/.config/guix/current/bin/guix system init \
  -L ~/.config/guixos ~/.config/guixos/guixos/guixos.scm /mnt
```

### 17. Reboot into the new system

```
sudo umount -R /mnt
```

Power off, remove the stick, and press F12 to choose the internal drive.
Let the machine reach the greeter once so `/etc/shadow` exists.

## Part D: first login on the internal disk

### 18. Set a password

Power off. Boot the stick, mount the internal root, and set the hash as in
step 8:

```
sudo mount -o subvol=@ /dev/nvme0n1p3 /mnt
set +H
HASH=$(openssl passwd -6 changeme)
sudo sed -i "s|^USER:!:|USER:${HASH}:|" /mnt/etc/shadow
sudo umount /mnt
```

Boot the internal drive, log in with `changeme`, and run `passwd`.

### 19. Connect, bring the repo, pull

```
sudo nmcli device wifi connect 'SSID' password 'PASSWORD'
```

Copy the repo to `~/Work/guixos`, link it to `~/.config/guixos` as in step
10, then pull as in step 11.

### 20. Apply the home configuration

```
~/.config/guix/current/bin/guix home reconfigure \
  -L ~/.config/guixos ~/.config/guixos/guixos/home.scm
```

Log out and back in. After this the `gosr` and `gohr` aliases are available.

## File systems on the new host

The host file mounts btrfs by label. `no-atime` is a generic mount flag, so
it goes in `flags`, and the btrfs-specific options go in `options`:

```scheme
(file-system
  (mount-point "/")
  (device (file-system-label "guixos"))
  (type "btrfs")
  (flags '(no-atime))
  (options "subvol=@,compress=zstd"))
```
