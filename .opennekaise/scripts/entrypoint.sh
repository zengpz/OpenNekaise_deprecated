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

# ── 4. Run user command ──────────────────────────────────────────────────────
# If no args or just "bash", drop into interactive shell
# If args like "gateway --bind lan", pass through to openclaw
export OPENCLAW_HOME

if [ "$#" -eq 0 ] || [ "$1" = "bash" ]; then
    echo ""
    echo "  OpenNekaise — building energy AI assistant"
    echo ""
    echo "  Get started:   opennekaise onboard"
    echo "  Configure:     opennekaise configure"
    echo "  Start gateway: opennekaise gateway --bind lan"
    echo ""
    echo "  Building data: $BUILDINGS_DIR/"
    echo ""
    exec bash
else
    exec openclaw "$@"
fi
