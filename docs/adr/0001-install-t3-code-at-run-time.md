# Install T3 Code at run time, not in the image

The image ships the toolchains but not T3 Code itself. On first start the entrypoint installs T3 Code with the official `install.sh` into the persisted home, and every start runs T3's own service launcher so T3 updates itself on its chosen Channel. T3 Code needs internet anyway and changes fast enough that an older baked-in server quickly stops working with current clients; its self-updater (trial start, commit or roll back, database backup) only works when T3 owns its install directory.

## Considered Options

- **Bake a pinned or `@latest` npm/pnpm install into the image.** Reproducible, but goes stale between image builds, fights T3's updater (npm-global installs only get a "copy update command"), and pnpm 10 blocks the native build scripts T3 needs.
- **`npx t3@latest` on every start.** No self-update, and every restart is a surprise upgrade.

## Consequences

- The image has its own semver, independent of T3 Code's version; an image update never downgrades T3.
- First start needs network access to `t3.codes` release downloads.
- The Provider CLIs follow the same rule for the same reason: T3 Code updates them with their own updater or `npm install -g --prefix` where they are installed, which fails on a root-owned image path. The entrypoint npm-installs them into `/home/dev/.local` on first start and approves their install scripts through `NPM_CONFIG_ALLOW_SCRIPTS`.
- If the service launcher proves unusable in a container, the fallback is an entrypoint that runs `t3 update` then `t3 serve`, so updates apply on the next restart.
