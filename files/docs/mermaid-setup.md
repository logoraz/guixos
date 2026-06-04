# Mermaid CLI (`mmdc`) — distrobox container

Runs [`@mermaid-js/mermaid-cli`](https://github.com/mermaid-js/mermaid-cli)
inside a distrobox container so the npm / Puppeteer / Chromium stack stays
out of the Guix system. The host exposes it through a bash alias in the
`home-bash` service (`mmdc` → `distrobox enter mermaid -- mmdc`).

The container is a *pet*: created and provisioned by hand (these steps),
not declared in the Guix config. Only the alias is declarative.

## Prerequisites

- `distrobox` and `podman` installed.
- `~/.config/containers/registries.conf` present (provided by the
  `home-config-files` service).

## 1. Create and enter the container

```sh
distrobox create --name mermaid \
  --image registry.fedoraproject.org/fedora-toolbox:41
distrobox enter mermaid
```

The first `enter` provisions the container and takes a minute. Everything
from here runs **inside** the container.

## 2. Install Node, Chromium, fonts, and mermaid-cli

```sh
sudo dnf install -y nodejs npm chromium google-noto-sans-fonts
sudo npm install -g @mermaid-js/mermaid-cli
```

The font package keeps diagram labels from rendering as missing-glyph
boxes.

## 3. Wrap `mmdc` for headless Chromium

Puppeteer must be pointed at the system Chromium and run with
`--no-sandbox` (the sandbox does not work inside the container). Baking
this into a wrapper keeps the host alias a plain `mmdc`.

> **Gotcha:** npm installs `mmdc` as a *symlink* to `cli.js`. Delete that
> symlink **before** writing the wrapper — otherwise `tee` follows it and
> overwrites `cli.js` with shell text, and Node then fails with
> `SyntaxError: Unexpected token 'export'`.

```sh
# resolve the real paths BEFORE removing the symlink
REAL=$(readlink -f "$(command -v mmdc)")
CHROME=$(command -v chromium-browser || command -v chromium)

# puppeteer launch args
echo '{ "args": ["--no-sandbox"] }' \
  | sudo tee /etc/mermaid-puppeteer.json >/dev/null

# delete the npm symlink, then write the wrapper as a real file
sudo rm -f /usr/local/bin/mmdc
sudo tee /usr/local/bin/mmdc >/dev/null <<EOF
#!/bin/sh
export PUPPETEER_EXECUTABLE_PATH=$CHROME
exec node "$REAL" -p /etc/mermaid-puppeteer.json "\$@"
EOF
sudo chmod +x /usr/local/bin/mmdc
hash -r
```

If headless Chromium still complains about the sandbox, add
`"--disable-gpu"` to the args array in `/etc/mermaid-puppeteer.json`.

## 4. Test inside the container

```sh
printf 'graph TD; A-->B;' > /tmp/t.mmd
mmdc -i /tmp/t.mmd -o /tmp/t.svg && echo OK
exit
```

Sanity check if it misbehaves: `head -1 "$REAL"` should print JavaScript
(a shebang or an `import`), not `#!/bin/sh`.

## 5. Host side

The alias lives in the `home-bash` service:

```scheme
(define %mmdc "distrobox enter mermaid -- mmdc")
;; ("mmdc"  . ,%mmdc) in the aliases list
```

Reconfigure home (`gohr`) and open a fresh shell. Then, from a directory
under `$HOME` (distrobox shares `$HOME`, so paths line up):

```sh
mmdc -i diagram.mmd -o diagram.svg
```

## Maintenance

- **Updating mermaid-cli:** `sudo npm install -g @mermaid-js/mermaid-cli`
  recreates the `mmdc` symlink and clobbers the wrapper. Rerun the
  path-resolution and wrapper steps in section 3 afterward.
- **Paths:** run real diagrams from under `$HOME` so the host and the
  container resolve the same files.
