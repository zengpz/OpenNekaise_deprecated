#!/usr/bin/env bash
# entrypoint.sh — OpenNekaise Docker container entrypoint
#
# Responsibilities:
#   1. Generate openclaw.json from defaults + environment variables (first run only)
#   2. Install base workspace files into the user-writable volume (first run only,
#      never overwrite user edits)
#   3. Start openclaw with the user's command
set -euo pipefail

OPENCLAW_HOME="${OPENCLAW_HOME:-/data/.openclaw}"
WORKSPACE="$OPENCLAW_HOME/workspace"
NEKAISE_BASE="/nekaise"

# ── 1. Directory setup ────────────────────────────────────────────────────────
mkdir -p \
    "$OPENCLAW_HOME" \
    "$WORKSPACE/skills" \
    "$OPENCLAW_HOME/logs" \
    "$OPENCLAW_HOME/memory"

# ── 2. Generate openclaw.json (first-run only) ────────────────────────────────
CONFIG="$OPENCLAW_HOME/openclaw.json"

if [ ! -f "$CONFIG" ]; then
    echo "[opennekaise] First run — generating openclaw.json ..."

    # Start from the OpenNekaise defaults template, inject workspace path and model
    jq \
        --arg workspace "$WORKSPACE" \
        --arg model "${OPENCLAW_MODEL:-openai-codex/gpt-5.3-codex}" \
        '.agents.defaults.workspace = $workspace | .agents.defaults.model.primary = $model' \
        "$NEKAISE_BASE/config/openclaw.defaults.json" \
        > "$CONFIG"

    # Helper: set a jq path only when the env var is non-empty
    jq_inject() {
        local val="$1"
        local jq_expr="$2"
        if [ -n "$val" ]; then
            local tmp
            tmp=$(mktemp)
            jq "$jq_expr" --arg v "$val" "$CONFIG" > "$tmp" && mv "$tmp" "$CONFIG"
        fi
    }

    # Telegram
    jq_inject "${TELEGRAM_BOT_TOKEN:-}" \
        '.channels.telegram.enabled = true | .channels.telegram.botToken = $v'

    # Slack
    if [ -n "${SLACK_BOT_TOKEN:-}" ] && [ -n "${SLACK_APP_TOKEN:-}" ]; then
        tmp=$(mktemp)
        jq \
            --arg bt "$SLACK_BOT_TOKEN" \
            --arg at "$SLACK_APP_TOKEN" \
            '.channels.slack.enabled = true | .channels.slack.botToken = $bt | .channels.slack.appToken = $at' \
            "$CONFIG" > "$tmp" && mv "$tmp" "$CONFIG"
    fi

    # Discord
    jq_inject "${DISCORD_BOT_TOKEN:-}" \
        '.channels.discord.enabled = true | .channels.discord.botToken = $v'

    # Gateway auth token
    jq_inject "${GATEWAY_TOKEN:-}" \
        '.gateway.auth.mode = "token" | .gateway.auth.token = $v'

    echo "[opennekaise] Config written to $CONFIG"
else
    echo "[opennekaise] Config exists — skipping generation (delete to regenerate)"
fi

# ── 3. Install base workspace (first-run only, never overwrite) ───────────────
for f in AGENTS.md SOUL.md TOOLS.md IDENTITY.md USER.md HEARTBEAT.md; do
    src="$NEKAISE_BASE/workspace/$f"
    dst="$WORKSPACE/$f"
    if [ -f "$src" ] && [ ! -f "$dst" ]; then
        cp "$src" "$dst"
        echo "[opennekaise]   Installed: $f"
    fi
done

# Base skills: only copy skills that don't already exist in the user's workspace
for skill_dir in "$NEKAISE_BASE/workspace/skills"/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name="$(basename "$skill_dir")"
    dst_skill="$WORKSPACE/skills/$skill_name"
    if [ ! -d "$dst_skill" ]; then
        cp -r "$skill_dir" "$dst_skill"
        echo "[opennekaise]   Installed skill: $skill_name"
    fi
done

# ── 4. Start openclaw ─────────────────────────────────────────────────────────
echo "[opennekaise] Starting openclaw $* ..."
export OPENCLAW_HOME
exec openclaw "$@"
