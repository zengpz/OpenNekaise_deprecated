# ============================================================
# OpenNekaise Docker image
# Based on OpenClaw (https://github.com/openclaw/openclaw)
# ============================================================

FROM node:22-bookworm-slim

# Pin openclaw version here. Update this line to track upstream.
ARG OPENCLAW_VERSION=latest
ARG NEKAISE_VERSION=1.0.0

LABEL org.opencontainers.image.title="OpenNekaise"
LABEL org.opencontainers.image.description="OpenNekaise — building energy AI assistant"
LABEL org.opencontainers.image.version="${NEKAISE_VERSION}"
LABEL org.opencontainers.image.based-on="openclaw@${OPENCLAW_VERSION}"

# ── Runtime dependencies ─────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    jq git ca-certificates \
    procps lsof \
    python3 make g++ libopus-dev \
    && rm -rf /var/lib/apt/lists/*

# Rewrite SSH git URLs to HTTPS (no SSH keys inside container)
RUN printf '[url "https://github.com/"]\n\tinsteadOf = ssh://git@github.com/\n\tinsteadOf = git@github.com:\n' > /root/.gitconfig

# ── Install OpenClaw at pinned version ───────────────────────────────────────
ENV GIT_TERMINAL_PROMPT=0
RUN npm install -g openclaw@${OPENCLAW_VERSION}

# ── Apply OpenNekaise branding patches to the installed package ──────────────
COPY .opennekaise/patches/apply-branding.sh /tmp/apply-branding.sh
RUN bash /tmp/apply-branding.sh && rm /tmp/apply-branding.sh

# ── Install CLI wrapper (container-safe gateway restart) ────────────────────
RUN mv "$(which openclaw)" /usr/local/bin/openclaw-bin
COPY .opennekaise/scripts/openclaw-wrapper.sh /usr/local/bin/openclaw
RUN chmod +x /usr/local/bin/openclaw \
    && ln -sf /usr/local/bin/openclaw /usr/local/bin/opennekaise

# ── Copy OpenNekaise agent pack (read-only reference inside image) ───────────
COPY .nekaiseagent/ /nekaise/workspace/

# ── Copy sample buildings (seeded into /home/ on first run) ──────────────────
COPY sample_buildings/ /nekaise/sample_buildings/

# ── Entrypoint ────────────────────────────────────────────────────────────────
COPY .opennekaise/scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# User-writable runtime volume (config, workspace link, memory, logs, buildings)
VOLUME ["/.opennekaise"]

ENV OPENCLAW_HOME=/.opennekaise

WORKDIR /home

ENTRYPOINT ["/entrypoint.sh"]
# Default: interactive shell so users can run `opennekaise onboard`
CMD ["bash"]
