#!/usr/bin/env bash
# entrypoint.sh — OpenNekaise Docker container entrypoint
#
# Responsibilities:
#   1. Create directory structure
#   2. Install base workspace files (first run only, never overwrite user edits)
#   3. Run whatever the user passes (default: bash for interactive use)
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

# ── 2. Install base workspace (first-run only, never overwrite) ───────────────
for f in AGENTS.md SOUL.md TOOLS.md IDENTITY.md USER.md HEARTBEAT.md MEMORY.md; do
    src="$NEKAISE_BASE/workspace/$f"
    dst="$WORKSPACE/$f"
    if [ -f "$src" ] && [ ! -f "$dst" ]; then
        cp "$src" "$dst"
        echo "[opennekaise] Installed: $f"
    fi
done

# Base skills: only copy skills that don't already exist in the user's workspace
for skill_dir in "$NEKAISE_BASE/workspace/skills"/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name="$(basename "$skill_dir")"
    dst_skill="$WORKSPACE/skills/$skill_name"
    if [ ! -d "$dst_skill" ]; then
        cp -r "$skill_dir" "$dst_skill"
        echo "[opennekaise] Installed skill: $skill_name"
    fi
done

# ── 3. Run user command ──────────────────────────────────────────────────────
# If no args or just "bash", drop into interactive shell
# If args like "gateway --bind lan", pass through to openclaw
export OPENCLAW_HOME

if [ "$#" -eq 0 ] || [ "$1" = "bash" ]; then
    echo ""
    echo "🏔️  OpenNekaise — building energy AI assistant"
    echo ""
    echo "  Get started:   opennekaise onboard"
    echo "  Configure:     opennekaise configure"
    echo "  Start gateway: opennekaise gateway --bind lan"
    echo ""
    exec bash
else
    exec openclaw "$@"
fi
