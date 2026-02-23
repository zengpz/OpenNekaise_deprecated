#!/usr/bin/env bash
# sync-workspace.sh — sync workspace files between this repo and the live location
#
# In Docker deployments the "live" workspace is inside the data volume:
#   ./data/.openclaw/workspace/
#
# In host deployments it's the standard openclaw home:
#   ~/.openclaw/workspace/
#
# Usage:
#   bash scripts/sync-workspace.sh              # dry-run: show what differs
#   bash scripts/sync-workspace.sh --push       # copy live → repo (save your edits)
#   bash scripts/sync-workspace.sh --pull       # copy repo → live  (apply updates)
#
# Optional env overrides:
#   LIVE_WORKSPACE=/path/to/workspace bash scripts/sync-workspace.sh

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_WORKSPACE="$REPO_DIR/workspace"

# Auto-detect live workspace: Docker volume takes priority over host install
if [ -n "${LIVE_WORKSPACE:-}" ]; then
    LIVE="$LIVE_WORKSPACE"
elif [ -d "$REPO_DIR/data/.openclaw/workspace" ]; then
    LIVE="$REPO_DIR/data/.openclaw/workspace"
elif [ -d "${OPENCLAW_HOME:-$HOME/.openclaw}/workspace" ]; then
    LIVE="${OPENCLAW_HOME:-$HOME/.openclaw}/workspace"
else
    echo "ERROR: Cannot find live workspace. Set LIVE_WORKSPACE= or start the container first."
    exit 1
fi

MODE="${1:-dry}"
FILES=(AGENTS.md SOUL.md TOOLS.md IDENTITY.md USER.md HEARTBEAT.md MEMORY.md)

echo "[opennekaise] Repo workspace : $REPO_WORKSPACE"
echo "[opennekaise] Live workspace : $LIVE"
echo ""

case "$MODE" in
  --push)
    echo "[opennekaise] Pushing live → repo ..."
    for f in "${FILES[@]}"; do
        [ -f "$LIVE/$f" ] && cp "$LIVE/$f" "$REPO_WORKSPACE/$f" && echo "  pushed: $f"
    done
    # Sync skills that are already tracked in the repo
    for skill_dir in "$REPO_WORKSPACE/skills"/*/; do
        [ -d "$skill_dir" ] || continue
        skill_name="$(basename "$skill_dir")"
        live_skill="$LIVE/skills/$skill_name"
        if [ -d "$live_skill" ]; then
            cp -r "$live_skill/." "$REPO_WORKSPACE/skills/$skill_name/"
            echo "  pushed skill: $skill_name"
        fi
    done
    echo ""
    echo "[opennekaise] Done. Review with: git diff $REPO_WORKSPACE"
    ;;

  --pull)
    echo "[opennekaise] Pulling repo → live ..."
    for f in "${FILES[@]}"; do
        [ -f "$REPO_WORKSPACE/$f" ] && cp "$REPO_WORKSPACE/$f" "$LIVE/$f" && echo "  pulled: $f"
    done
    for skill_dir in "$REPO_WORKSPACE/skills"/*/; do
        [ -d "$skill_dir" ] || continue
        skill_name="$(basename "$skill_dir")"
        mkdir -p "$LIVE/skills/$skill_name"
        cp -r "$skill_dir/." "$LIVE/skills/$skill_name/"
        echo "  pulled skill: $skill_name"
    done
    echo ""
    echo "[opennekaise] Done."
    ;;

  dry|--dry)
    echo "[opennekaise] Dry run — comparing files ..."
    echo ""
    any_diff=0
    for f in "${FILES[@]}"; do
        repo_f="$REPO_WORKSPACE/$f"
        live_f="$LIVE/$f"
        if [ -f "$repo_f" ] && [ -f "$live_f" ]; then
            if diff -q "$repo_f" "$live_f" &>/dev/null; then
                printf "  %-10s %s\n" "OK" "$f"
            else
                printf "  %-10s %s\n" "DIFFERS" "$f"
                any_diff=1
            fi
        elif [ -f "$live_f" ] && [ ! -f "$repo_f" ]; then
            printf "  %-10s %s  (run --push to add to repo)\n" "LIVE_ONLY" "$f"
            any_diff=1
        elif [ ! -f "$live_f" ] && [ -f "$repo_f" ]; then
            printf "  %-10s %s  (run --pull to install)\n" "REPO_ONLY" "$f"
            any_diff=1
        fi
    done
    echo ""
    if [ "$any_diff" -eq 0 ]; then
        echo "All files in sync."
    else
        echo "Usage:"
        echo "  $0 --push   save live edits → repo"
        echo "  $0 --pull   apply repo → live workspace"
    fi
    ;;

  *)
    echo "Unknown mode: $MODE"
    echo "Usage: $0 [--push|--pull|--dry]"
    exit 1
    ;;
esac
