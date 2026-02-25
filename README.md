# 🏔️ OpenNekaise

OpenNekaise is a distribution of [OpenClaw](https://github.com/openclaw/openclaw) that ships **Nekaise Agent** — your virtual building manager.

Nekaise Agent lives in Slack, understands HVAC, district heating, PV systems, BMS, indoor climate, and building physics. 
It monitors your buildings, answers questions about hardwares, energy use and comfort, and helps you act on what matters. 

---

## Prerequisites

- Docker Engine + Docker Compose plugin
- Run commands as your regular user (avoid `sudo`, or you can if you know what you are doing!)

---

## Quick start

```bash
# 1. Clone and build
git clone https://github.com/OpenNekaise/OpenNekaise.git opennekaise && cd opennekaise
docker compose build

# 2. Start the container
docker compose up -d

# 3. Attach and run the onboarding wizard
docker exec -it nekaise opennekaise onboard
```

The onboarding wizard walks you through:
- Choosing your LLM backend (OpenAI, Anthropic, OpenRouter)
- Setting up chat channels (Telegram, WhatsApp, Slack)
- Configuring the gateway

After onboarding, start the gateway (runs in background):

```bash
docker exec -d nekaise opennekaise gateway
```

---

## Building data

Building data is split into **templates** (tracked) and **runtime** (gitignored):

| Directory | Tracked? | Purpose |
|---|---|---|
| `sample_buildings/` | Yes | Sample buildings shipped with the repo |
| `home/` | No (gitignored) | Your actual building data — the agent works here |

On first container start, the sample buildings are automatically copied into `home/` so you have something to explore right away. After that, `home/` is yours — add, remove, or modify buildings freely. Nothing in `home/` ever touches git.

```
sample_buildings/              ← in the repo (read-only templates)
├── axelsdgården-32/
├── centraltorp-42/
├── duvbacken-2/
└── weather-station/

home/                          ← on your machine only (gitignored)
├── axelsdgården-32/           ← auto-seeded on first run
├── my-real-building/          ← your own data
└── ...
```

To add a building, just drop a folder into `home/` with your CSV files, PDFs, logs, TTL models, or anything else the agent should have access to.

---

## Other useful commands

```bash
# Inside the container:
opennekaise configure            # Re-run the configuration wizard
opennekaise gateway   # Start the gateway
opennekaise gateway restart      # Restart gateway (container-safe fallback)

# On the host:
docker compose logs -f           # Follow logs
docker compose down              # Stop
docker compose build             # Rebuild after changes
```

When running inside the OpenNekaise container (no `systemd`), `gateway restart` uses a fallback restart path automatically and writes logs to `/.opennekaise/logs/opennekaise-gateway.log`.

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
├── sample_buildings/           ← Sample building data (tracked, seeded into home/)
├── home/                      ← Runtime building data (gitignored, volume-mounted)
├── Dockerfile
├── docker-compose.yml
└── README.md
```

### What lives where

| Directory | Role | In image? | Persisted? |
|---|---|---|---|
| `.nekaiseagent/` | Agent brain — persona, rules, domain knowledge | Baked in read-only | N/A (source in repo) |
| `.opennekaise/patches/`, `scripts/` | Build-time infra — branding, entrypoint | Used during build | N/A (source in repo) |
| `.opennekaise/runtime/` | Runtime state — config, agent memory, logs | Volume-mounted | Yes (survives rebuilds) |
| `sample_buildings/` | Sample building data (seeded into `home/` on first run) | Baked in read-only | N/A (source in repo) |
| `home/` | Your building data (the agent works here) | Volume-mounted at `/home/` | Yes (on host) |

---

## Updating OpenClaw

By default, every `docker compose build` pulls the latest OpenClaw version. Just rebuild to update:

```bash
docker compose build && docker compose up -d
```

To pin a specific version, set `OPENCLAW_VERSION` in your `.env`:

```bash
OPENCLAW_VERSION=2026.2.21-2
```

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Your data (volumes, persisted on host)                     │
│                                                             │
│   ./home/                    building data (CSV, PDF, …)    │
│   ./.opennekaise/runtime/    agent memory, config, logs     │
├─────────────────────────────────────────────────────────────┤
│  OpenNekaise (this repo, read-only in image)                │
│                                                             │
│   .nekaiseagent/             agent brain (persona, skills)  │
│   .opennekaise/              infra (patches, entrypoint)    │
│   sample_buildings/          templates seeded into home/    │
├─────────────────────────────────────────────────────────────┤
│  OpenClaw (npm package, latest by default)                  │
│                                                             │
│   Installed via npm install -g inside Docker image          │
│   Override with OPENCLAW_VERSION in .env to pin             │
└─────────────────────────────────────────────────────────────┘
```
