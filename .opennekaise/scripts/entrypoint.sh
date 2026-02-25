#!/usr/bin/env bash
# entrypoint.sh — OpenNekaise Docker container entrypoint
#
# Responsibilities:
#   1. Create user-writable directory structure
#   2. Point openclaw workspace to the read-only OpenNekaise pack
#   3. Run whatever the user passes (default: bash for interactive use)
set -euo pipefail

OPENCLAW_HOME_DEFAULT="/.opennekaise"
OPENCLAW_HOME_LEGACY="/.openclaw"
OPENCLAW_HOME="${OPENCLAW_HOME:-$OPENCLAW_HOME_DEFAULT}"
BUILDINGS_DIR="${NEKAISE_BUILDINGS_DIR:-/home}"
NEKAISE_BASE="/nekaise"

# ── 1. Runtime home migration/compatibility ───────────────────────────────────
# New default: /.opennekaise
# Legacy path: /.openclaw (auto-migrated when possible)
if [ "$OPENCLAW_HOME" = "$OPENCLAW_HOME_DEFAULT" ]; then
    if [ -d "$OPENCLAW_HOME_LEGACY" ] && [ ! -L "$OPENCLAW_HOME_LEGACY" ] && [ ! -e "$OPENCLAW_HOME_DEFAULT" ]; then
        mv "$OPENCLAW_HOME_LEGACY" "$OPENCLAW_HOME_DEFAULT"
        echo "[opennekaise] Migrated runtime home: $OPENCLAW_HOME_LEGACY -> $OPENCLAW_HOME_DEFAULT"
    fi

    if [ -e "$OPENCLAW_HOME_LEGACY" ] && [ -e "$OPENCLAW_HOME_DEFAULT" ] && [ ! -L "$OPENCLAW_HOME_LEGACY" ]; then
        echo "[opennekaise] Note: both $OPENCLAW_HOME_DEFAULT and $OPENCLAW_HOME_LEGACY exist."
        echo "[opennekaise] Using $OPENCLAW_HOME_DEFAULT as OPENCLAW_HOME."
    fi
fi

# ── 2. Directory setup ────────────────────────────────────────────────────────
mkdir -p \
    "$OPENCLAW_HOME/logs" \
    "$OPENCLAW_HOME/memory" \
    "$BUILDINGS_DIR"

# ── 2b. Seed sample buildings on first run ────────────────────────────────────
SAMPLE_SRC="$NEKAISE_BASE/sample_buildings"
if [ -d "$SAMPLE_SRC" ] && [ -z "$(ls -A "$BUILDINGS_DIR" 2>/dev/null)" ]; then
    cp -a "$SAMPLE_SRC"/. "$BUILDINGS_DIR"/
    echo "[opennekaise] Seeded sample buildings into $BUILDINGS_DIR/"
fi

# ── 2c. Create user memory file ──────────────────────────────────────────────
MEMORY_FILE="$OPENCLAW_HOME/memory/user.md"
if [ ! -f "$MEMORY_FILE" ]; then
    cat > "$MEMORY_FILE" <<'USERMEM'
# User Memory

This file is where Nekaise Agent stores user-specific knowledge:
building names, preferences, learned patterns, and domain context.

It is read at session start and updated as the agent learns.
USERMEM
    echo "[opennekaise] Created $MEMORY_FILE"
fi

# ── 2d. Create core memory scaffolding expected by AGENTS.md ─────────────────
LONGTERM_MEMORY_FILE="$OPENCLAW_HOME/memory/MEMORY.md"
if [ ! -f "$LONGTERM_MEMORY_FILE" ]; then
    cat > "$LONGTERM_MEMORY_FILE" <<'LONGMEM'
# Long-Term Memory

Curated, stable notes for direct sessions.
Keep this concise and update as priorities evolve.
LONGMEM
    echo "[opennekaise] Created $LONGTERM_MEMORY_FILE"
fi

TODAY_NOTE_FILE="$OPENCLAW_HOME/memory/$(date +%F).md"
if [ ! -f "$TODAY_NOTE_FILE" ]; then
    cat > "$TODAY_NOTE_FILE" <<EOF
# Daily Notes ($(date +%F))

- Session notes:
EOF
    echo "[opennekaise] Created $TODAY_NOTE_FILE"
fi

YESTERDAY_NOTE_FILE="$OPENCLAW_HOME/memory/$(date -d 'yesterday' +%F).md"
if [ ! -f "$YESTERDAY_NOTE_FILE" ]; then
    cat > "$YESTERDAY_NOTE_FILE" <<EOF
# Daily Notes ($(date -d 'yesterday' +%F))

- Session notes:
EOF
    echo "[opennekaise] Created $YESTERDAY_NOTE_FILE"
fi

# ── 3. Workspace lives read-only inside the image ────────────────────────────
# OpenClaw reads workspace from $OPENCLAW_HOME/workspace — symlink to the
# baked-in OpenNekaise pack from this repo.
if [ ! -L "$OPENCLAW_HOME/workspace" ] && [ ! -d "$OPENCLAW_HOME/workspace" ]; then
    ln -s "$NEKAISE_BASE/workspace" "$OPENCLAW_HOME/workspace"
    echo "[opennekaise] Workspace linked to $NEKAISE_BASE/workspace (read-only)"
elif [ -d "$OPENCLAW_HOME/workspace" ] && [ ! -L "$OPENCLAW_HOME/workspace" ]; then
    echo "[opennekaise] Note: user workspace directory exists at $OPENCLAW_HOME/workspace"
    echo "[opennekaise] Remove it to use the default read-only workspace."
fi

# ── 4. Patch OpenClaw config with OpenNekaise defaults ───────────────────────
# The configure wizard sets its own workspace path and channel defaults.
# Override selected keys every start so runtime behavior stays consistent.
OC_CONFIG="$OPENCLAW_HOME/.openclaw/openclaw.json"
NEKAISE_WORKSPACE="$OPENCLAW_HOME/workspace"
if [ -f "$OC_CONFIG" ] && command -v jq >/dev/null 2>&1; then
    OC_PATCH="$(mktemp)"
    if jq --arg ws "$NEKAISE_WORKSPACE" '
        .agents.defaults.workspace = $ws
        | (.channels //= {})
        | (.channels.slack //= {})
        | .channels.slack.replyToMode = "all"
        | (.channels.slack.replyToModeByChatType //= {})
        | .channels.slack.replyToModeByChatType.channel = "all"
    ' "$OC_CONFIG" > "$OC_PATCH"; then
        if ! cmp -s "$OC_PATCH" "$OC_CONFIG"; then
            mv "$OC_PATCH" "$OC_CONFIG"
            echo "[opennekaise] Patched config defaults: workspace + Slack channel thread replies"
        else
            rm -f "$OC_PATCH"
        fi
    else
        rm -f "$OC_PATCH"
    fi
fi

# ── 5. Run user command ──────────────────────────────────────────────────────
# If no args or just "bash", drop into interactive shell
# If args like "gateway --bind lan", pass through to openclaw
export OPENCLAW_HOME

if [ "$#" -eq 0 ] || [ "$1" = "bash" ]; then
    echo ""
    echo "  OpenNekaise — building energy AI assistant"
    echo ""
    echo "  Get started:   opennekaise onboard"
    echo "  Configure:     opennekaise configure"
    echo "  Start gateway: opennekaise gateway"
    echo ""
    echo "  Building data: $BUILDINGS_DIR/"
    echo ""
    exec bash
else
    exec openclaw "$@"
fi
