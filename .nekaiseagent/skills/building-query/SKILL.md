---
name: building-query
description: "Query and analyze building data files (CSV, TTL/RDF, logs) from the /home directory"
metadata:
  openclaw:
    emoji: "🏢"
    requires:
      bins: ["python3"]
    always: true
---

# Building Query

You have access to building data stored in `/home/`. Each subfolder represents one building or data source.

## When to use

- User asks about building energy data, sensor readings, or building metadata
- User asks to analyze CSV files, RDF/TTL models, or log files
- User asks to compare data across buildings
- User wants summaries or visualizations of building performance

## Data layout

```
/home/
├── <building-slug>/
│   ├── *.csv          — time-series sensor data
│   ├── *.ttl          — RDF/Turtle building models (Brick Schema / ASHRAE 223P)
│   ├── *.pdf          — documentation, reports
│   ├── *.log          — system logs
│   └── generated/     — outputs you create (plots, reports)
```

## How to work

1. **List buildings:** `ls /home/` to see available buildings
2. **Explore a building:** `ls /home/<building>/` to see available files
3. **Read metadata:** For TTL files, parse RDF triples to understand building topology
4. **Analyze data:** Use python3 for CSV analysis (pandas if available, otherwise csv module)
5. **Save outputs:** Write generated files to `/home/<building>/generated/`

## Conventions

- In Slack, the channel name maps to the building folder (e.g., channel `<building-slug>` → `/home/<building-slug>`)
- When the context implies a specific building, use that mapping
- Always confirm the building folder exists before querying
- Use ontology docs in `{baseDir}/../../internal-docs/ontology/` for RDF/TTL interpretation

## Example queries

- "What sensors are in building X?" → Parse the TTL model
- "Show me last week's temperatures" → Analyze CSV data
- "Compare energy use across buildings" → Aggregate from multiple folders
