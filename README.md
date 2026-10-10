# GuixOS


<p align="center">
  <img src="files/assets/graphics/gx-guixos.svg"
       height="300" hspace="15" align="absmiddle" />
</p>


GuixOS: Flagship Guix System Configuration for Sway (WIP Mahogany) and more...


## Overview

Declarative Guix System + Home config, parameterized per host and per window
manager. This configuration is set up as a Guile program.


## Architecture

- `make-guixos-system` and `guixos-home` build an
  `operating-system`/`home-environment` from keyword arguments.
- Each host is a thin file under `system/hosts/` that exports `%host-profile`
  (name, user, comment, window manager) and `host-operating-system` (a thunk).
- `host.scm` is the only file to edit when switching machines; both
  `guixos.scm` (system) and `home.scm` (home) read the host from it.
- Nothing host-specific lives in the constructors themselves; nothing shared
  lives in a host file.
- Expected at `~/.config/guixos`: `config-source` hardcodes this path;
  anything else requires editing `identity.scm`.


## Hosts

- `framework`: primary laptop, Sway.
- `framework-pro`: second machine, same config; its window manager is set in
  its `%host-profile`.
- `locutus`: template host for setting up Mahogany.

To switch machines, change the one `#:use-module` line in `host.scm`.


## Window Managers

- **Sway**: complete. Home config, keybindings, status bar (gubar) and session
  lifecycle live in `home/window-manager/sway.scm`; the greeter session
  command and screen locker are selected in `system/system.scm`.
- **Mahogany**: in progress. `home/window-manager/mahogany.scm` is a stub and
  the system side has placeholder branches; a host switches window manager by
  changing the `window-manager` field of its `%host-profile`.
- WM-agnostic desktop packages (themes, codecs, office, etc.) live in
  `desktop-profile.scm` and apply regardless of window manager.
- WM-agnostic desktop utilities (foot, mako, fuzzel and the wlogout layout
  generator) live in `desktop-utilities.scm`.


## Channels & Substitutes

- Pinned via `channels.scm`, resolved through a plain `guix pull`, not
  `guix-for-channels`, which silently went stale.
- Substitute servers: nonguix, ci.guix.gnu.org, bordeaux.


## Usage

- `guix pull` / `sudo guix system reconfigure`: system generation.
- `guix home reconfigure`: home generation, independent of system.
- Shell aliases (`gop`, `gosr`, `gostm`, `gohr`, `gohtm`) wrap the above with
  the right `-L` load path baked in.


## Status

- [x] Split `sway.scm` into WM-specific vs. shared desktop-utilities
- [x] Parameterize system and home by window manager
- [x] Explicit per-host profile selected from `host.scm`
- [ ] Stand up `window-manager/mahogany.scm` (system + home); stub in place


## License

Take it, tweak it, tuck it into your own dotfiles; sharing is the whole point.
GuixOS is released under the GNU Lesser General Public License, version 2.1
only, with the Lisp Lesser General Public License (LLGPL) preamble. In plain
words: use these modules the ordinary Lisp way (call the functions, expand the
macros, subclass the classes) and your own code stays yours, while changes to
the files themselves flow back under the same terms. The full text is in
`LICENSE`. Bits borrowed from elsewhere keep their original licenses.

There is no warranty. If a reconfigure eats your laptop, that is between you
and your generations; `guix system roll-back` is your friend.
