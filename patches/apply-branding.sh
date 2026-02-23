#!/usr/bin/env bash
# apply-branding.sh — Patch brand strings in the installed openclaw npm package.
#
# Strategy: replace only hard-coded literal strings (brand name, emoji).
# Never touch logic, control flow, or variable names.
# If a pattern isn't found the patch silently succeeds — safe for future updates.
set -euo pipefail

PKG="$(npm root -g)/openclaw"

if [ ! -d "$PKG" ]; then
    echo "[opennekaise] ERROR: openclaw package not found at $PKG"
    exit 1
fi

echo "[opennekaise] Patching openclaw @ $PKG"

patch_file() {
    local f="$1"
    local before="$2"
    local after="$3"
    if grep -qF "$before" "$f" 2>/dev/null; then
        sed -i "s|$(printf '%s' "$before" | sed 's/[[\.*^$()+?{|]/\\&/g')|$after|g" "$f"
        echo "[opennekaise]   $(basename "$f"): '$before' → '$after'"
    fi
}

# ── Brand name in onboard terminal banner ─────────────────────────────────────
# "🦞 OpenClaw" appears in the onboard wizard header
for f in "$PKG"/dist/*.js; do
    patch_file "$f" "🦞 OpenClaw" "🏔️  OpenNekaise"
done

# ── Standalone lobster emoji used as section markers ─────────────────────────
for f in "$PKG"/dist/*.js; do
    # Only replace when the emoji is the full value of a string literal
    sed -i 's/"🦞"/"🏔️"/g' "$f" 2>/dev/null || true
done

# ── Skills: patch SKILL.md files that show the brand name to users ────────────
# (upstream skill descriptions sometimes reference "OpenClaw" by name)
for f in "$PKG"/skills/*/SKILL.md; do
    [ -f "$f" ] || continue
    if grep -qiF "openclaw" "$f" 2>/dev/null; then
        sed -i 's/OpenClaw/OpenNekaise/g; s/openclaw/opennekaise/g' "$f"
        echo "[opennekaise]   skill: $(basename "$(dirname "$f")")/SKILL.md"
    fi
done

echo "[opennekaise] Done."
