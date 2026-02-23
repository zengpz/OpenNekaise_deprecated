# 🏔️ OpenNekaise

Building energy AI assistant — a distribution of [OpenClaw](https://github.com/openclaw/openclaw).

OpenNekaise is a pre-configured OpenClaw agent for HVAC, district heating, PV systems, indoor climate, and building physics. It ships as a Docker image — users pull it, run the interactive onboarding wizard, and configure their own LLM backend and chat channels.

---

## Quick start

```bash
# 1. Clone and build
git clone https://github.com/zengpz/OpenNekaise.git opennekaise && cd opennekaise
docker compose build

# 2. Start the container
docker compose up -d

# 3. Attach and run the onboarding wizard
docker exec -it nekaise bash
opennekaise onboard
```

The onboarding wizard walks you through:
- Choosing your LLM backend (OpenAI, Anthropic, local models, etc.)
- Setting up chat channels (Telegram, Slack, Discord)
- Configuring the gateway

After onboarding, start the gateway:
```bash
opennekaise gateway --bind lan
```

All user data is persisted in `./data/` on the host and survives container rebuilds.

---

## Other useful commands

```bash
# Inside the container:
opennekaise configure       # Re-run the configuration wizard
opennekaise gateway --bind lan  # Start the gateway

# On the host:
docker compose logs -f      # Follow logs
docker compose down         # Stop
docker compose build        # Rebuild after changes
```

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

---

## Tracking upstream OpenClaw updates

```bash
# 1. Update OPENCLAW_VERSION in .env
OPENCLAW_VERSION=2026.x.x

# 2. Rebuild
docker compose build

# 3. Restart
docker compose up -d
```

---

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│                     User layer (volume)                   │
│  ./data/.openclaw/           ← config, workspace, memory │
│  Persisted on host, never overwritten by image updates   │
├──────────────────────────────────────────────────────────┤
│              OpenNekaise layer (this repo)                │
│  workspace/   ← base workspace (baked in image)          │
│  patches/     ← branding patches                         │
│  scripts/     ← entrypoint.sh                            │
├──────────────────────────────────────────────────────────┤
│              OpenClaw (npm package, pinned version)       │
│  Installed inside Docker image via npm install -g        │
│  Version pinned in .env (OPENCLAW_VERSION)               │
└──────────────────────────────────────────────────────────┘
```
