# ============================================================
# OpenNekaise Docker image
# Based on OpenClaw (https://github.com/openclaw/openclaw)
# ============================================================

FROM node:22-bookworm-slim

# Pin openclaw version here. Update this line to track upstream.
ARG OPENCLAW_VERSION=2026.2.21-2
ARG NEKAISE_VERSION=1.0.0

LABEL org.opencontainers.image.title="OpenNekaise"
LABEL org.opencontainers.image.description="OpenNekaise — building energy AI assistant"
LABEL org.opencontainers.image.version="${NEKAISE_VERSION}"
LABEL org.opencontainers.image.based-on="openclaw@${OPENCLAW_VERSION}"

# ── Runtime dependencies ─────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    jq git ca-certificates \
    python3 make g++ libopus-dev \
    && rm -rf /var/lib/apt/lists/*

# Rewrite SSH git URLs to HTTPS (no SSH keys inside container)
RUN printf '[url "https://github.com/"]\n\tinsteadOf = ssh://git@github.com/\n\tinsteadOf = git@github.com:\n' > /root/.gitconfig

# ── Install OpenClaw at pinned version ───────────────────────────────────────
ENV GIT_TERMINAL_PROMPT=0
RUN npm install -g openclaw@${OPENCLAW_VERSION}

# ── Apply OpenNekaise branding patches to the installed package ──────────────
COPY patches/apply-branding.sh /tmp/apply-branding.sh
RUN bash /tmp/apply-branding.sh && rm /tmp/apply-branding.sh

# ── Create `opennekaise` CLI alias ──────────────────────────────────────────
RUN ln -s "$(which openclaw)" /usr/local/bin/opennekaise

# ── Copy OpenNekaise base workspace (read-only reference inside image) ────────
COPY workspace/ /nekaise/workspace/

# ── Copy default config template ─────────────────────────────────────────────
COPY config/openclaw.defaults.json /nekaise/config/openclaw.defaults.json

# ── Entrypoint ────────────────────────────────────────────────────────────────
COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# User-writable data volume (config, workspace, memory, logs)
VOLUME ["/data"]

ENV OPENCLAW_HOME=/data/.openclaw

ENTRYPOINT ["/entrypoint.sh"]
# Default: interactive shell so users can run `opennekaise onboard`
CMD ["bash"]
