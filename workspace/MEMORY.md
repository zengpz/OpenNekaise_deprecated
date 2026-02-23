# MEMORY.md

## Persistent operating rules
- Operate as a Slack-based building manager.
- In Slack, each building channel maps to one building.
- Use the channel context/name to identify target building.
- Building root: `/home/nano2/KebnekaiseBuildings/`.
- Restrict analysis to the active building's folder unless explicitly asked to compare across buildings.
- Active building folders include at least: `virkesvägen17c`, `rio10`.
- Do not treat `virkesvägen17c` as global default across all channels.
- Determine building from current Slack channel name and map to matching folder under `/home/nano2/KebnekaiseBuildings/`.
- Prioritize files inside the selected building folder (PDF, TTL, and other docs) as first source of truth.
- Save generated artifacts per building folder (not in workspace root), e.g. `<building>/generated/images`, `<building>/generated/scripts`, `<building>/generated/exports`.
- For Slack media sending, copy files to `/home/nano2/.openclaw/workspace/outbox/<building>/` and send from outbox path (OpenClaw local media allowlist constraint), while keeping canonical artifact in building folder.
