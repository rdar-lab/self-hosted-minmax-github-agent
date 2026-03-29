FROM ubuntu:24.04

# GitHub Actions runner version — keep in sync with SHA256 args below.
# Get the latest version + hashes from:
# https://github.com/actions/runner/releases/latest
ARG RUNNER_VERSION=2.333.0
ARG RUNNER_SHA256_X64=7ce6b3fd8f879797fcc252c2918a23e14a233413dc6e6ab8e0ba8768b5d54475
ARG RUNNER_SHA256_ARM64=b5697062a13f63b44f869de9369638a7039677b9e0f87e47a6001a758c0d09bf

ARG NODE_VERSION=22
ARG PYTHON_VERSION=3.12.12

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# ── System dependencies (includes pyenv build deps) ───────────────────────────
RUN apt-get update && apt-get install -y \
    curl \
    git \
    jq \
    sudo \
    ca-certificates \
    gnupg \
    openssh-client \
    unzip \
    gh \
    build-essential \
    libssl-dev \
    zlib1g-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    libncurses-dev \
    xz-utils \
    tk-dev \
    libxml2-dev \
    libxmlsec1-dev \
    libffi-dev \
    liblzma-dev \
    && rm -rf /var/lib/apt/lists/*

# ── Python (exact version via pyenv) ──────────────────────────────────────────
ENV PYENV_ROOT=/opt/pyenv
ENV PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"

RUN curl -fsSL https://pyenv.run | bash \
    && pyenv install ${PYTHON_VERSION} \
    && pyenv global ${PYTHON_VERSION}

# ── Node.js ────────────────────────────────────────────────────────────────────
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# ── Claude Code CLI (configured to use MiniMax API) ───────────────────────────
RUN npm install -g @anthropic-ai/claude-code

# ── Runner user ────────────────────────────────────────────────────────────────
RUN useradd -m -s /bin/bash runner \
    && echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# ── GitHub Actions runner ──────────────────────────────────────────────────────
# Detect architecture so the image builds on both amd64 and arm64 hosts.
RUN ARCH=$(uname -m) \
    && case "$ARCH" in \
         x86_64)  RUNNER_ARCH=x64;   RUNNER_SHA256="${RUNNER_SHA256_X64}" ;; \
         aarch64) RUNNER_ARCH=arm64; RUNNER_SHA256="${RUNNER_SHA256_ARM64}" ;; \
         *)        echo "Unsupported architecture: $ARCH" && exit 1 ;; \
       esac \
    && mkdir -p /home/runner/actions-runner \
    && cd /home/runner/actions-runner \
    && curl -fsSL -o actions-runner.tar.gz \
         "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz" \
    && if [ -n "$RUNNER_SHA256" ]; then \
         echo "${RUNNER_SHA256}  actions-runner.tar.gz" | sha256sum -c; \
       else \
         echo "WARNING: no SHA256 provided for this architecture, skipping checksum validation"; \
       fi \
    && tar xzf actions-runner.tar.gz \
    && rm actions-runner.tar.gz \
    && ./bin/installdependencies.sh \
    && chown -R runner:runner /home/runner /opt/pyenv

COPY entrypoint.sh /home/runner/entrypoint.sh
RUN chmod +x /home/runner/entrypoint.sh \
    && chown runner:runner /home/runner/entrypoint.sh

USER runner
WORKDIR /home/runner

ENTRYPOINT ["/home/runner/entrypoint.sh"]
