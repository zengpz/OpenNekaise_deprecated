# OpenNekaise

Building energy AI assistant — a distribution of [OpenClaw](https://github.com/openclaw/openclaw).

**Agent:** OpenNekaise Agent — HVAC, district heating, PV, indoor climate, building physics.
**Deployment:** Docker image. Users run `docker compose up -d` and get the full stack.

---

## Architecture — three layers

```
┌──────────────────────────────────────────────────────────┐
│                     User layer (volume)                   │
│  ./data/.openclaw/openclaw.json  ← generated from .env   │
│  ./data/.openclaw/workspace/     ← user edits go here    │
│  ./data/.openclaw/memory/        ← agent memory          │
│  ./data/.openclaw/logs/          ← runtime logs          │
│  Persisted on host, never overwritten by image updates   │
├──────────────────────────────────────────────────────────┤
│              OpenNekaise layer (this repo)                │
│  workspace/   ← OpenNekaise base workspace (baked in image)  │
│  config/      ← Config template (secrets from env vars)  │
│  patches/     ← Brand string patches to openclaw dist    │
│  scripts/     ← entrypoint.sh, sync-workspace.sh         │
│  Dockerfile, docker-compose.yml, .env.example            │
├──────────────────────────────────────────────────────────┤
│              OpenClaw (npm package, pinned version)       │
│  Installed inside Docker image via npm install -g        │
│  Version pinned in .env (OPENCLAW_VERSION)               │
│  Update: change version → docker compose build           │
└──────────────────────────────────────────────────────────┘
```

**Key property:** the user-writable volume (`./data/`) survives image rebuilds and upstream updates. The entrypoint only writes files that don't exist yet — it never overwrites user edits.

---

## Quick start

```bash
# 1. Clone
git clone <this-repo> opennekaise && cd opennekaise

# 2. Configure secrets
cp .env.example .env
$EDITOR .env          # fill in TELEGRAM_BOT_TOKEN, SLACK_BOT_TOKEN, etc.

# 3. Build and run
docker compose up -d

# 4. Follow logs
docker compose logs -f
```

On first run, `./data/.openclaw/` is created with:
- `openclaw.json` — generated from `.env` values
- `workspace/` — OpenNekaise base files (AGENTS.md, SOUL.md, skills, …)

---

## Tracking upstream OpenClaw updates

```bash
# 1. Find the new version
npm view openclaw version

# 2. Update OPENCLAW_VERSION in .env
OPENCLAW_VERSION=2026.x.x

# 3. Rebuild the image
docker compose build

# 4. Restart
docker compose up -d
```

The upstream changelog is at https://github.com/openclaw/openclaw/blob/main/CHANGELOG.md.
Brand patches (`patches/apply-branding.sh`) use string-literal matching, so they're
resilient to upstream changes unless the brand strings themselves move.

---

## Customizing the agent

### Base workspace (tracked in this repo)

Files in `workspace/` are the OpenNekaise defaults baked into the Docker image.
Edit them here, commit, and rebuild the image.

| File | Purpose |
|---|---|
| `workspace/AGENTS.md` | Operating rules — how the agent behaves |
| `workspace/SOUL.md` | Identity — who the agent is |
| `workspace/IDENTITY.md` | Domain expertise definition |
| `workspace/USER.md` | Stakeholder profiles + audience adaptation |
| `workspace/TOOLS.md` | Tool notes and local config |
| `workspace/HEARTBEAT.md` | Periodic task checklist |
| `workspace/skills/kebnekaise-buildings/` | Building domain skill |

### User workspace (persisted in `./data/`, not in repo)

Users can freely edit files in `./data/.openclaw/workspace/`. These are never
overwritten by image updates. Add new skills, modify AGENTS.md, etc.

### Syncing between repo and live workspace

```bash
# Check what differs between repo and running volume
bash scripts/sync-workspace.sh

# Save live edits back to the repo
bash scripts/sync-workspace.sh --push

# Apply repo changes to live workspace
bash scripts/sync-workspace.sh --pull
```

---

## Workspace / skills structure

```
./data/.openclaw/workspace/       ← user-writable (Docker volume)
├── AGENTS.md                     ← installed from image on first run
├── SOUL.md
├── IDENTITY.md
├── USER.md
├── TOOLS.md
├── HEARTBEAT.md
├── memory/                       ← agent daily memory logs
└── skills/
    ├── kebnekaise-buildings/     ← installed from image on first run
    │   └── SKILL.md
    └── (your own skills)         ← add freely, never overwritten
```

---

## Branding patches

`patches/apply-branding.sh` runs during `docker build` and patches the installed
openclaw npm package with OpenNekaise brand strings.

What gets patched:
- Terminal onboard banner: `🦞 OpenClaw` → `🏔️  Nekaise`
- Bundled skill SKILL.md files: `OpenClaw` → `OpenNekaise`

What is NOT patched (intentional):
- `docs.openclaw.ai` URLs — they point to real upstream documentation
- Internal variable names and logic — never touched
- The `openclaw` CLI command name — internal only, users never type it

---

## Building data

Building files live at `/home/nano2/KebnekaiseBuildings/` on the host.
The building domain skill (`kebnekaise-buildings`) documents how the agent uses them.
See [`workspace/skills/kebnekaise-buildings/SKILL.md`](workspace/skills/kebnekaise-buildings/SKILL.md).
