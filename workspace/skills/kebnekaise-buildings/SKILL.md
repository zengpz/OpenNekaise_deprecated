# Skill: kebnekaise-buildings

Building energy intelligence for KebnekaiseBuildings managed properties.

## Purpose

Analyze, monitor, and explain energy data from buildings managed via KebnekaiseBuildings.
Covers HVAC, district heating, PV systems, indoor climate, and control sequences.

## Data Root

`/home/nano2/KebnekaiseBuildings/`

Each building has its own subdirectory. Active buildings:

- `virkesvägen17c/`
- `rio10/`

## Operating Rules

1. Determine the target building from the current Slack channel name (channel = building).
2. Work exclusively within that building's folder unless a cross-building comparison is explicitly requested.
3. Read source documents (PDF, TTL, CSV, etc.) from the building folder before answering.
4. Save generated outputs inside the building folder:
   - Plots/figures → `generated/images/`
   - Scripts → `generated/scripts/`
   - Exports (CSV/JSON/tables) → `generated/exports/`
5. For Slack media: copy to `/home/nano2/.openclaw/workspace/outbox/<building>/` then send from there (OpenClaw local media allowlist constraint). Keep canonical file in building folder.

## Ontologies in Use

- **Brick Schema** — entity and relationship modeling
- **RealEstateCore (REC)** — real estate domain semantics
- **ASHRAE 223P** — system component connections

See `/home/nano2/KebnekaiseBuildings/documentations/ontology/` for reference documents.

## Response Style by Audience

| Audience | Focus | Style |
|---|---|---|
| Property owners | Cost, comfort, overall health | Plain language, no sensor codes |
| BMS engineers | Diagnostics, trends, anomalies | Technical precision, point tags OK |
| BAS engineers | Control sequences, commissioning | Loop/setpoint language |
| Researchers | Analysis, model validation | Method-aware, assumption-explicit |

Infer audience from question wording. State assumption if uncertain.

## Key Sensor Naming Conventions

Sensor tags follow the building's BMS naming. Common patterns:

- `GT*` — temperature sensors
- `SV*` — control valves
- `VVX*` — heat exchangers
- `DH*` — district heating circuit

Always explain sensor tags in context when answering property owners.

## Typical Tasks

- "Why is my energy bill high this month?" → cross-reference heating demand, outdoor temp, occupancy
- "Is VVX efficiency degrading?" → trend GT in/out delta vs flow
- "Detect simultaneous heating+cooling" → find overlapping valve open states
- "Export January power data as CSV" → save to `generated/exports/`, upload to Slack outbox
