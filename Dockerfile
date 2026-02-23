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
    jq \
    && rm -rf /var/lib/apt/lists/*

# ── Install OpenClaw at pinned version ───────────────────────────────────────
RUN npm install -g openclaw@${OPENCLAW_VERSION}

# ── Apply OpenNekaise branding patches to the installed package ──────────────
COPY patches/apply-branding.sh /tmp/apply-branding.sh
RUN bash /tmp/apply-branding.sh && rm /tmp/apply-branding.sh

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
# Default: run the gateway, bound to all LAN interfaces
CMD ["gateway", "--bind", "lan"]
