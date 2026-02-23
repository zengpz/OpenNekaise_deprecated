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

# Helper: safe sed replacement in a file (no error if pattern not found)
patch_file() {
    local f="$1"
    local before="$2"
    local after="$3"
    if grep -qF "$before" "$f" 2>/dev/null; then
        sed -i "s|$(printf '%s' "$before" | sed 's/[[\.*^$()+?{|]/\\&/g')|$after|g" "$f"
        echo "[opennekaise]   $(basename "$f"): '$before' → '$after'"
    fi
}

# ── Patch all .js files in dist/ ─────────────────────────────────────────────
for f in "$PKG"/dist/*.js; do
    [ -f "$f" ] || continue

    # Brand name in banner / headers
    patch_file "$f" "🦞 OpenClaw" "🏔️  OpenNekaise"
    patch_file "$f" "🦞 OPENCLAW 🦞" "🏔️  OPENNEKAISE 🏔️"

    # Onboarding wizard title
    patch_file "$f" "OpenClaw onboarding" "OpenNekaise onboarding"

    # Security notice — rebrand OpenClaw references
    patch_file "$f" "OpenClaw is a hobby project and still in beta. Expect sharp edges." \
        "OpenNekaise is a building energy AI assistant built on OpenClaw. It helps with HVAC, district heating, PV, indoor climate, and building physics."

    patch_file "$f" "don't run OpenClaw" "don't run OpenNekaise"

    patch_file "$f" "openclaw security audit" "opennekaise security audit"

    # Standalone lobster emoji used as section markers → mountain
    sed -i 's/"🦞"/"🏔️"/g' "$f" 2>/dev/null || true

    # Remove the ASCII block-letter "OPENCLAW" banner
    sed -i '/▄▄▄▄/d; /██░/d; /▀▀▀▀/d' "$f" 2>/dev/null || true
done

# ── Skills: patch SKILL.md files that show the brand name to users ────────────
for f in "$PKG"/skills/*/SKILL.md; do
    [ -f "$f" ] || continue
    if grep -qiF "openclaw" "$f" 2>/dev/null; then
        sed -i 's/OpenClaw/OpenNekaise/g; s/openclaw/opennekaise/g' "$f"
        echo "[opennekaise]   skill: $(basename "$(dirname "$f")")/SKILL.md"
    fi
done

echo "[opennekaise] Done."
