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
        "OpenNekaise is an open-source distribution of OpenClaw that ships Nekaise Agent — an AI agent that interacts with people based on building data you provide."

    patch_file "$f" "don't run OpenClaw" "don't run OpenNekaise"

    patch_file "$f" "openclaw security audit" "opennekaise security audit"

    # Standalone lobster emoji used as section markers → mountain
    sed -i 's/"🦞"/"🏔️"/g' "$f" 2>/dev/null || true

    # Remove the ASCII block-letter "OPENCLAW" banner
    sed -i '/▄▄▄▄/d; /██░/d; /▀▀▀▀/d' "$f" 2>/dev/null || true
done

# ── Trim onboarding provider list to keep only selected providers ─────────────
for f in "$PKG"/dist/auth-choice-options-*.js; do
    [ -f "$f" ] || continue
    node -e '
const fs = require("fs");
const path = require("path");
const f = process.argv[1];
let src = fs.readFileSync(f, "utf8");

const keepGroups = new Set(["openai", "anthropic", "openrouter"]);
const keepChoices = new Set([
    "token", "openai-codex", "openai-api-key", "apiKey", "openrouter-api-key",
    "skip", "custom-api-key"
]);

// Parse array of objects by tracking brace depth
function extractObjects(arrayStr) {
    const objects = [];
    let depth = 0, start = -1;
    for (let i = 0; i < arrayStr.length; i++) {
        if (arrayStr[i] === "{") { if (depth === 0) start = i; depth++; }
        else if (arrayStr[i] === "}") { depth--; if (depth === 0 && start >= 0) { objects.push(arrayStr.slice(start, i + 1)); start = -1; } }
    }
    return objects;
}

function getValue(objStr) {
    const m = objStr.match(/value:\s*"([^"]+)"/);
    return m ? m[1] : null;
}

let changed = false;

// Patch AUTH_CHOICE_GROUP_DEFS
src = src.replace(/const AUTH_CHOICE_GROUP_DEFS = \[([\s\S]*?)\n\];/, (full, inner) => {
    const objs = extractObjects(inner);
    const kept = objs.filter(o => keepGroups.has(getValue(o)));
    if (kept.length === objs.length) return full;
    changed = true;
    return "const AUTH_CHOICE_GROUP_DEFS = [\n" + kept.map(s => "        " + s.trim()).join(",\n") + "\n];";
});

// Patch BASE_AUTH_CHOICE_OPTIONS
src = src.replace(/const BASE_AUTH_CHOICE_OPTIONS = \[([\s\S]*?)\n\];/, (full, inner) => {
    const objs = extractObjects(inner);
    const kept = objs.filter(o => keepChoices.has(getValue(o)));
    if (kept.length === objs.length) return full;
    changed = true;
    return "const BASE_AUTH_CHOICE_OPTIONS = [\n" + kept.map(s => "        " + s.trim()).join(",\n") + "\n];";
});

if (changed) {
    fs.writeFileSync(f, src);
    console.log("[opennekaise]   " + path.basename(f) + ": trimmed provider list");
}
' "$f" || true
done

# ── Trim onboarding channel list to keep only selected channels ───────────────
# Patch CHAT_CHANNEL_ORDER in entry.js to keep only telegram, whatsapp, slack
if [ -f "$PKG/dist/entry.js" ]; then
    node -e '
const fs = require("fs");
const f = process.argv[1];
let src = fs.readFileSync(f, "utf8");
const replaced = src.replace(
    /const CHAT_CHANNEL_ORDER = \[[\s\S]*?\];/,
    "const CHAT_CHANNEL_ORDER = [\n\t\"telegram\",\n\t\"whatsapp\",\n\t\"slack\"\n];"
);
if (replaced !== src) {
    fs.writeFileSync(f, replaced);
    console.log("[opennekaise]   entry.js: trimmed channel list to telegram, whatsapp, slack");
}
' "$PKG/dist/entry.js" || true
fi

# Filter out plugin catalog channels from onboard-channels files
# Replace the catalog lookup to return an empty array so only core channels show
for f in "$PKG"/dist/onboard-channels-*.js; do
    [ -f "$f" ] || continue
    node -e '
const fs = require("fs");
const path = require("path");
const f = process.argv[1];
let src = fs.readFileSync(f, "utf8");
// Make listChannelPluginCatalogEntries always return [] so plugin channels are hidden
const replaced = src.replace(
    /listChannelPluginCatalogEntries\(\{[^}]*\}\)/g,
    "[]"
);
if (replaced !== src) {
    fs.writeFileSync(f, replaced);
    console.log("[opennekaise]   " + path.basename(f) + ": disabled plugin catalog channels");
}
' "$f" || true
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
