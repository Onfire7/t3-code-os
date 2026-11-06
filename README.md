<img src="assets/icon.svg" width="64" height="64" alt="">

# T3 Code OS

A sandboxed, headless [T3 Code](https://t3.codes) Remote Environment, packaged
as a container for a [Maître](https://github.com/Onfire7/maitre-de-serveur)
Node. Pair the desktop app, app.t3.codes or a browser with it; Claude Code and
Codex then work inside the container, never on the host.

Vocabulary is in [GLOSSARY.md](GLOSSARY.md); decisions in [docs/adr](docs/adr).

## What's in the image

`debian:trixie-slim` (amd64) with git, gh, ripgrep, fd, jq, curl, ssh,
build-essential, Python 3, Node LTS + pnpm, Rust (rustup, clippy, rustfmt),
Go, and the libraries and fonts for T3's headless browser. It runs as `dev`
(uid 1000).

T3 Code and the Provider CLIs are **not** in the image. On first start the
entrypoint installs T3 Code with `install.sh` into `/home/dev/.t3`, and
Claude Code and Codex with npm into `/home/dev/.local`, then runs T3 under its
own service launcher. T3 Code updates itself in place on its Channel and
updates the Provider CLIs where they are installed
([ADR 0001](docs/adr/0001-install-t3-code-at-run-time.md)). Set
`T3_OS_MODE=serve` to fall back to reinstalling on each start and running
`t3 serve` instead.

| Path         | Holds                                                     |
| ------------ | --------------------------------------------------------- |
| `/home/dev`  | T3 state, Provider Logins, T3 Connect link, caches        |
| `/workspace` | projects; a Space folder on Maître, group-writable        |

## First-time setup

1. **Pair.** Copy the pairing link from the Service's Logs (`/pair#token=…`),
   swapping its address for the Service's `.local` or `ts.net` name. Later
   devices: run `t3 pair` in T3's terminal on a paired device.
2. **Provider Login.** In T3's terminal: `claude`, then `/login`; and
   `codex login --device-auth`.
3. **Account Link (optional).** In T3's terminal: `t3 connect --headless`,
   approve the code, then restart the Service.

## Releasing

Push a `vX.Y.Z` tag: CI publishes `ghcr.io/onfire7/t3-code-os:X.Y.Z` (and
`X.Y`, `X`). Then pin the tag's digest in `catalog/t3-code/manifest.yaml` and
copy the entry to `maitre-catalog/entries/t3-code/`. A weekly run rebuilds the
latest tag for Debian patches; the Catalog's `catalog outdated` job repins it.

## Local testing

```sh
just run    # build, then serve on http://127.0.0.1:3774
just logs   # the pairing link
just reset  # remove the container and its home volume
```
