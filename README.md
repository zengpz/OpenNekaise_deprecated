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

All user runtime data is persisted in `./.opennekaise/runtime/` on the host and survives container rebuilds.
Agent pack source files live in `./.opennekaise/` and are baked into the image.

---

## Adding your buildings

Place building data folders in your home folder on the host:

```
~/opennekaise-buildings/
├── my-building-1/     ← your data (CSV, PDF, logs, etc.)
├── my-building-2/
└── ...
```

Each subfolder represents one building. The folder is mounted into the container as `/buildings/`, and the agent uses `/buildings/` by default.
If the host folder does not exist, create it with:
```bash
mkdir -p ~/opennekaise-buildings
```

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

### Agent pack files (baked into the image)

The agent's core design files live in `./.opennekaise/` and are baked read-only into the Docker image. Edit them here, commit, and rebuild.

| File | Purpose |
|---|---|
| `.opennekaise/AGENTS.md` | Operating rules — how the agent behaves |
| `.opennekaise/SOUL.md` | Identity — who the agent is |
| `.opennekaise/IDENTITY.md` | Domain expertise definition |
| `.opennekaise/USER.md` | Stakeholder profiles + audience adaptation |
| `.opennekaise/TOOLS.md` | Tool notes and environment config |
| `.opennekaise/HEARTBEAT.md` | Periodic task checklist |
| `.opennekaise/internal-docs/` | Versioned internal references (ontology + operating doctrine) |

Runtime state is separate and not versioned: `./.opennekaise/runtime/` (mounted into the container).

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
│                     User data (volume)                    │
│  ~/opennekaise-buildings/        ← building data (CSV…)   │
│  ./.opennekaise/runtime/           ← config, memory, logs│
│  Persisted on host, survives container rebuilds           │
├──────────────────────────────────────────────────────────┤
│              OpenNekaise layer (this repo)                │
│  .opennekaise/ ← agent pack source (baked read-only)     │
│  patches/     ← branding patches                         │
│  scripts/     ← entrypoint.sh                            │
├──────────────────────────────────────────────────────────┤
│              OpenClaw (npm package, pinned version)       │
│  Installed inside Docker image via npm install -g        │
│  Version pinned in .env (OPENCLAW_VERSION)               │
└──────────────────────────────────────────────────────────┘
```
