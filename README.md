# 🏔️ OpenNekaise

A distribution of [OpenClaw](https://github.com/openclaw/openclaw) that ships **Nekaise Agent** — your virtual building manager.

OpenNekaise packages everything you need to run Nekaise Agent, an AI-powered building manager that understands HVAC, district heating, PV systems, indoor climate, and building physics. It monitors your buildings, answers questions about energy use and comfort, and helps you act on what matters. Ships as a Docker image with interactive onboarding — bring your own LLM backend and connect your chat channels.

---

## Prerequisites

- Docker Engine + Docker Compose plugin
- Run commands as your regular user (avoid `sudo`)

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

---

## Adding your buildings

Drop building data folders into `home/` at the repo root:

```
home/
├── my-building-1/     ← CSV, PDF, logs, etc.
├── my-building-2/
└── ...
```

Each subfolder is one building. The directory is mounted into the container at `/home/`, where the agent looks for building data by default. Contents of `home/` are gitignored — only the directory itself is tracked.

---

## Other useful commands

```bash
# Inside the container:
opennekaise configure            # Re-run the configuration wizard
opennekaise gateway --bind lan   # Start the gateway

# On the host:
docker compose logs -f           # Follow logs
docker compose down              # Stop
docker compose build             # Rebuild after changes
```

---

## Project structure

```
OpenNekaise/
├── .nekaiseagent/             ← Agent pack (baked read-only into image)
│   ├── AGENTS.md              ← Operating rules
│   ├── SOUL.md                ← Core identity
│   ├── IDENTITY.md            ← Domain expertise definition
│   ├── USER.md                ← Stakeholder profiles + audience adaptation
│   ├── TOOLS.md               ← Tool notes and environment config
│   ├── HEARTBEAT.md           ← Periodic task checklist
│   ├── internal-docs/         ← Ontology + operating references
│   └── skills/                ← Custom skills
├── .opennekaise/              ← Project infra (OpenClaw → OpenNekaise)
│   ├── patches/               ← Branding patches
│   ├── scripts/               ← Entrypoint and helpers
│   └── runtime/               ← Runtime state (gitignored, volume-mounted)
├── home/                      ← Building data (volume-mounted into container)
├── Dockerfile
├── docker-compose.yml
├── .env / .env.example
└── README.md
```

### What lives where

| Directory | Role | In image? | Persisted? |
|---|---|---|---|
| `.nekaiseagent/` | Agent brain — persona, rules, domain knowledge | Baked in read-only | N/A (source in repo) |
| `.opennekaise/patches/`, `scripts/` | Build-time infra — branding, entrypoint | Used during build | N/A (source in repo) |
| `.opennekaise/runtime/` | Runtime state — config, memory, logs | Volume-mounted | Yes (survives rebuilds) |
| `home/` | User building data | Volume-mounted at `/home/` | Yes (on host) |

---

## Customizing the agent

The agent pack lives in `.nekaiseagent/`. Edit the files, commit, and rebuild the image.

| File | Purpose |
|---|---|
| `AGENTS.md` | Operating rules — how the agent behaves |
| `SOUL.md` | Identity — who the agent is |
| `IDENTITY.md` | Domain expertise and building data paths |
| `USER.md` | Stakeholder profiles and audience adaptation |
| `TOOLS.md` | Tool notes and environment config |
| `HEARTBEAT.md` | Periodic task checklist |
| `internal-docs/` | Versioned references (ontology, operating doctrine) |

---

## Tracking upstream OpenClaw updates

```bash
# 1. Create .env from the example (if you haven't already)
cp .env.example .env

# 2. Update OPENCLAW_VERSION in .env
OPENCLAW_VERSION=2026.x.x

# 3. Rebuild and restart
docker compose build && docker compose up -d
```

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  User data (volumes, persisted on host)                     │
│                                                             │
│   ./home/                    building data (CSV, PDF, …)    │
│   ./.opennekaise/runtime/    config, memory, logs           │
├─────────────────────────────────────────────────────────────┤
│  OpenNekaise layer (this repo)                              │
│                                                             │
│   .nekaiseagent/   agent pack — baked read-only into image  │
│   .opennekaise/    project infra — patches, entrypoint      │
├─────────────────────────────────────────────────────────────┤
│  OpenClaw (npm package, pinned version)                     │
│                                                             │
│   Installed via npm install -g inside Docker image          │
│   Version pinned in .env (OPENCLAW_VERSION)                 │
└─────────────────────────────────────────────────────────────┘
```
