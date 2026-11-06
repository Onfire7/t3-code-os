# T3 Code OS: a sandboxed, headless T3 Code Remote Environment.
# T3 Code itself is installed at run time into the home volume (docs/adr/0001).
# Layers run from least to most frequently changed, so updates pull little.

FROM docker.io/library/debian:trixie-slim

ARG NODE_VERSION=26.13.0
ARG GO_VERSION=1.27.3
ARG GO_SHA256=65efbc80fdc1fa2cd2631cad5b481777a68e8725f34e89f50fc6ac714e379b40
ARG RUST_VERSION=1.99.1

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

# OS packages: dev tools, compilers, and the libraries and fonts T3's headless browser loads.
RUN apt-get update && apt-get install -y --no-install-recommends \
      bash-completion build-essential ca-certificates curl fd-find gh git jq less \
      openssh-client pkg-config procps python3 python3-venv ripgrep tini unzip wget xz-utils \
      libnss3 libglib2.0-0t64 libatk1.0-0t64 libatk-bridge2.0-0t64 libatspi2.0-0t64 \
      libdbus-1-3 libx11-6 libxcb1 libxcomposite1 libxdamage1 libxext6 libxfixes3 \
      libxrandr2 libxkbcommon0 libgbm1 libasound2t64 libexpat1 \
      fontconfig fonts-liberation fonts-noto-core fonts-noto-color-emoji \
 && ln -s /usr/bin/fdfind /usr/local/bin/fd \
 && rm -rf /var/lib/apt/lists/*

# Non-root user. The home and Workspace are volumes; see catalog/t3-code.
RUN useradd --create-home --uid 1000 --shell /bin/bash dev \
 && install -d -o dev -g dev /workspace

# Go, from the official tarball.
RUN curl -fsSLo /tmp/go.tgz "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" \
 && echo "${GO_SHA256}  /tmp/go.tgz" | sha256sum -c - \
 && tar -C /opt -xzf /tmp/go.tgz && rm /tmp/go.tgz

# Rust via rustup. The toolchain dir is dev-owned so `rustup` works in a
# terminal; additions there last until the container is recreated.
ENV RUSTUP_HOME=/opt/rustup
RUN curl -fsSLo /tmp/rustup-init https://static.rust-lang.org/rustup/dist/x86_64-unknown-linux-gnu/rustup-init \
 && echo "$(curl -fsSL https://static.rust-lang.org/rustup/dist/x86_64-unknown-linux-gnu/rustup-init.sha256 | cut -d' ' -f1)  /tmp/rustup-init" | sha256sum -c - \
 && chmod +x /tmp/rustup-init \
 && CARGO_HOME=/opt/cargo /tmp/rustup-init -y --no-modify-path --profile minimal \
      --default-toolchain "${RUST_VERSION}" --component clippy,rustfmt \
 && rm /tmp/rustup-init \
 && chown -R dev:dev /opt/rustup /opt/cargo

# Node, from the official tarball, checked against its published sums.
RUN cd /tmp \
 && curl -fsSLO "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" \
 && curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/SHASUMS256.txt" | grep " node-v${NODE_VERSION}-linux-x64.tar.xz\$" | sha256sum -c - \
 && tar -C /usr/local --strip-components=1 --no-same-owner -xJf "node-v${NODE_VERSION}-linux-x64.tar.xz" \
 && rm "node-v${NODE_VERSION}-linux-x64.tar.xz"

# pnpm. The Provider CLIs install into the home volume at run time instead,
# so T3 Code can update them in place.
RUN npm install -g --no-fund --no-audit pnpm && npm cache clean --force

COPY rootfs/ /

ENV PATH=/home/dev/.local/bin:/home/dev/.local/share/pnpm:/home/dev/.cargo/bin:/home/dev/go/bin:/opt/cargo/bin:/opt/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    CARGO_HOME=/home/dev/.cargo \
    GOPATH=/home/dev/go \
    NPM_CONFIG_PREFIX=/home/dev/.local \
    PNPM_HOME=/home/dev/.local/share/pnpm \
    NPM_CONFIG_ALLOW_SCRIPTS=@anthropic-ai/claude-code,@openai/codex \
    T3CODE_HOME=/home/dev/.t3 \
    T3CODE_HOST=0.0.0.0 \
    T3CODE_PORT=3773 \
    T3CODE_NO_BROWSER=1 \
    T3CODE_TELEMETRY_ENABLED=false \
    T3CODE_SERVER_BROWSER_SANDBOX=0 \
    T3CODE_CHANNEL=stable \
    T3_OS_MODE=launcher

USER dev
WORKDIR /workspace
EXPOSE 3773
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/t3-os-entrypoint"]
