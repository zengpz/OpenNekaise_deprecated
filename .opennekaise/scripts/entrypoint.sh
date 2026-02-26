#!/usr/bin/env bash
# entrypoint.sh — OpenNekaise Docker container entrypoint
#
# Responsibilities:
#   1. Create user-writable directory structure
#   2. Bridge workspace memory paths to durable runtime memory
#   3. Emit explicit BOOT_* startup status diagnostics
#   4. Run whatever the user passes (default: bash for interactive use)
set -euo pipefail

OPENCLAW_HOME_DEFAULT="/.opennekaise"
OPENCLAW_HOME_LEGACY="/.openclaw"
OPENCLAW_HOME="${OPENCLAW_HOME:-$OPENCLAW_HOME_DEFAULT}"
BUILDINGS_DIR="${NEKAISE_BUILDINGS_DIR:-/home}"
NEKAISE_BASE="/nekaise"
TODAY="$(date +%F)"
YESTERDAY="$(date -d 'yesterday' +%F)"

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
    "$OPENCLAW_HOME/outbox" \
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

healthcheck_keyword: nekaise-memory-sentinel
USERMEM
    echo "[opennekaise] Created $MEMORY_FILE"
fi

if ! grep -q "nekaise-memory-sentinel" "$MEMORY_FILE"; then
    printf '\nhealthcheck_keyword: nekaise-memory-sentinel\n' >> "$MEMORY_FILE"
    echo "[opennekaise] Added memory health-check sentinel to $MEMORY_FILE"
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

TODAY_NOTE_FILE="$OPENCLAW_HOME/memory/$TODAY.md"
if [ ! -f "$TODAY_NOTE_FILE" ]; then
    cat > "$TODAY_NOTE_FILE" <<EOF
# Daily Notes ($TODAY)

- Session notes:
EOF
    echo "[opennekaise] Created $TODAY_NOTE_FILE"
fi

YESTERDAY_NOTE_FILE="$OPENCLAW_HOME/memory/$YESTERDAY.md"
if [ ! -f "$YESTERDAY_NOTE_FILE" ]; then
    cat > "$YESTERDAY_NOTE_FILE" <<EOF
# Daily Notes ($YESTERDAY)

- Session notes:
EOF
    echo "[opennekaise] Created $YESTERDAY_NOTE_FILE"
fi

# ── 3. Workspace setup and memory path bridging ───────────────────────────────
# OpenClaw reads workspace from $OPENCLAW_HOME/workspace.
# By default this points to the baked OpenNekaise pack from this repo.
if [ ! -L "$OPENCLAW_HOME/workspace" ] && [ ! -d "$OPENCLAW_HOME/workspace" ]; then
    ln -s "$NEKAISE_BASE/workspace" "$OPENCLAW_HOME/workspace"
    echo "[opennekaise] Workspace linked to $NEKAISE_BASE/workspace"
elif [ -d "$OPENCLAW_HOME/workspace" ] && [ ! -L "$OPENCLAW_HOME/workspace" ]; then
    echo "[opennekaise] Note: user workspace directory exists at $OPENCLAW_HOME/workspace"
    echo "[opennekaise] Keeping user workspace directory."
fi

WORKSPACE_DIR="$OPENCLAW_HOME/workspace"
WORKSPACE_MEMORY_PATH="$WORKSPACE_DIR/memory"
WORKSPACE_MEMORY_FILE="$WORKSPACE_DIR/MEMORY.md"
WORKSPACE_OUTBOX_PATH="$WORKSPACE_DIR/outbox"

if [ ! -e "$WORKSPACE_MEMORY_PATH" ]; then
    if ln -s "$OPENCLAW_HOME/memory" "$WORKSPACE_MEMORY_PATH"; then
        echo "[opennekaise] Linked workspace memory -> $OPENCLAW_HOME/memory"
    fi
fi

if [ ! -e "$WORKSPACE_MEMORY_FILE" ]; then
    if ln -s "$OPENCLAW_HOME/memory/MEMORY.md" "$WORKSPACE_MEMORY_FILE"; then
        echo "[opennekaise] Linked workspace MEMORY.md -> $OPENCLAW_HOME/memory/MEMORY.md"
    fi
fi

if [ ! -e "$WORKSPACE_OUTBOX_PATH" ]; then
    if ln -s "$OPENCLAW_HOME/outbox" "$WORKSPACE_OUTBOX_PATH"; then
        echo "[opennekaise] Linked workspace outbox -> $OPENCLAW_HOME/outbox"
    fi
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

# ── 5. Boot file diagnostics (BOOT_OK / BOOT_WARN / BOOT_FAIL) ──────────────
BOOT_FAILED=0
REQUIRED_BOOT_FILES=(
    "$OPENCLAW_HOME/memory/user.md"
    "$OPENCLAW_HOME/workspace/AGENTS.md"
    "$OPENCLAW_HOME/workspace/internal-docs/how_to_work_here.md"
)

OPTIONAL_BOOT_FILES=(
    "$OPENCLAW_HOME/workspace/SOUL.md"
    "$OPENCLAW_HOME/workspace/USER.md"
    "$OPENCLAW_HOME/workspace/IDENTITY.md"
    "$OPENCLAW_HOME/workspace/MEMORY.md"
    "$OPENCLAW_HOME/workspace/memory/$TODAY.md"
    "$OPENCLAW_HOME/workspace/memory/$YESTERDAY.md"
)

for path in "${REQUIRED_BOOT_FILES[@]}"; do
    if [ ! -e "$path" ]; then
        echo "BOOT_FAIL_MISSING_REQUIRED:$path"
        BOOT_FAILED=1
    fi
done

for path in "${OPTIONAL_BOOT_FILES[@]}"; do
    if [ ! -e "$path" ]; then
        echo "BOOT_WARN_MISSING_OPTIONAL:$path"
    fi
done

if [ "$BOOT_FAILED" -ne 0 ]; then
    exit 1
fi

echo "BOOT_OK"

# ── 6. Run user command ──────────────────────────────────────────────────────
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
