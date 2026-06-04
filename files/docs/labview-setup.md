# LabVIEW 2026 Community Edition — distrobox container

Runs LabVIEW 2026 Q1 Community Edition inside an openSUSE Leap distrobox
container. The host launches it from a `.desktop` entry defined in the
`home-config-files` service:

    Exec=env TERM=xterm-256color distrobox enter labview -- labview

The container is a *pet*: created and provisioned by hand (these steps),
not declared in the Guix config. Only the desktop launcher is declarative.

## Prerequisites

- `distrobox` and `podman` installed.
- `~/.config/containers/registries.conf` present (provided by the
  `home-config-files` service).
- The LabVIEW Community Edition Linux archive downloaded from NI (free
  account required): `ni-labview-2026-community-26.1.1_linux.zip`. Put it
  somewhere under `$HOME` (e.g. `~/Desktop/labview/`) so it is visible
  inside the container — distrobox shares `$HOME`.

## 1. Create and enter the container

```sh
distrobox create --name labview \
  --image registry.opensuse.org/opensuse/leap:15.6
distrobox enter labview
```

Everything from here runs **inside** the container.

## 2. Register NI's repository from the downloaded archive

The archive contains a small bootstrap RPM that adds NI's package
repository. Unzip and install it; NI's GPG key isn't trusted yet, hence
`--no-gpg-checks`:

```sh
cd ~/Desktop/labview/
unzip ni-labview-2026-community-26.1.1_linux.zip
sudo zypper --no-gpg-checks install \
  ni-labview-2026-community-26.1.1.49170-0+f18-opensuse156.noarch.rpm
sudo zypper refresh
```

This registers the `ni-labview-2026-lp156-community` repo:
`https://download.ni.com/ni-linux-desktop/LabVIEW/2026/Q1/f1/community/rpm/ni-labview-2026/lp156`

## 3. Install LabVIEW

```sh
sudo zypper install labview-2026-community
```

That metapackage pulls the full stack from the NI repo: the
`labview-2026-*` packages (`-community-exe`, `-exe-libs`, `-rte`) plus the
`ni-*` runtime (`ni-wine`, `ni-syscfg-runtime`, `ni-service-locator`,
`ni-sysapi`, and friends). Community Edition is free, so there is **no**
license-manager / activation step at install time — LabVIEW prompts for
account sign-in on first launch.

## 4. Put `labview` on PATH

The installer drops the binary at
`/usr/local/natinst/LabVIEW-2026-64/labviewcommunity`. Symlink it to a
short name on PATH — this is what both the shell and the desktop launcher
invoke:

```sh
sudo ln -s /usr/local/natinst/LabVIEW-2026-64/labviewcommunity \
  /usr/local/bin/labview
labview   # first run: NI account sign-in + Community Edition activation
```

## 5. (Optional) terminal info

If you enter the container from `foot`, install its terminfo so an
interactive `distrobox enter labview` behaves. The desktop launcher
already sidesteps this by forcing `TERM=xterm-256color`.

openSUSE Leap 15.6 ships the entries as `foot-extra` / `foot-extra-direct`
(no plain `foot-terminfo` package), so symlinks are needed to make
`TERM=foot` resolve:

```sh
sudo zypper install foot-extra-terminfo
sudo ln -s foot-extra        /usr/share/terminfo/f/foot
sudo ln -s foot-extra-direct /usr/share/terminfo/f/foot-direct
exit
```

## 6. Launcher (declarative)

Defined in the `home-config-files` service and installed to
`~/.local/share/applications/labview.desktop`:

```scheme
(define %labview-desktop
  (mixed-text-file
   "labview.desktop"
   "[Desktop Entry]\n"
   "Name=LabVIEW\n"
   ;; ...
   "Exec=env TERM=xterm-256color distrobox enter labview -- labview\n"
   "Icon=/home/" (%home-user)
   "/.local/share/icons/distrobox/opensuse-leap.png\n"
   ;; ...
   ))
;; (".local/share/applications/labview.desktop" ,%labview-desktop)
```

After `gohr`, LabVIEW appears in your application launcher.

## Maintenance / notes

- **New LabVIEW release:** download the new NI archive, install its
  bootstrap RPM, `sudo zypper refresh`, then
  `sudo zypper install labview-<year>-community`. The install path becomes
  `/usr/local/natinst/LabVIEW-<year>-64/`, so repoint the
  `/usr/local/bin/labview` symlink to the new `labviewcommunity`.
- The container is a pet; these steps are its rebuild recipe.
- The launcher assumes the container is named `labview` and that `labview`
  resolves inside it (the symlink from step 4).
