# Skills

Each subfolder is a skill. The only required file is `SKILL.md`.

## How the agent discovers skills

OpenClaw scans `workspace/skills/` at session start. Each skill's
`SKILL.md` YAML frontmatter is parsed for metadata and gating conditions.
Eligible skills are injected into the system prompt automatically.

**Three-tier precedence** (highest wins):

| Tier      | Location                          | Scope           |
|-----------|-----------------------------------|-----------------|
| Workspace | `<workspace>/skills/`             | This agent only |
| Managed   | `~/.openclaw/skills/`             | All agents      |
| Bundled   | Shipped in the openclaw npm pkg   | All agents      |

Workspace skills override managed and bundled skills of the same name.

## Skill folder layout

```
skills/
  my-skill/
    SKILL.md          ← required (frontmatter + instructions)
    helper.js         ← optional supporting files
    templates/        ← optional subdirectories
```

## SKILL.md format

```markdown
---
name: my-skill
description: "Short description of what this skill does"
metadata:
  openclaw:
    emoji: "🔧"
    requires:
      bins: ["curl"]           # CLI tools that must exist in PATH
      env: ["MY_API_KEY"]      # env vars that must be set
    os: ["linux", "darwin"]    # platform restrictions (optional)
    always: false              # bypass all gates (optional)
---

Instructions for the agent on when and how to use this skill.

Use `{baseDir}` to reference the skill's own folder at runtime.
```

## Gating conditions

Skills are filtered at load time based on:

- `requires.bins` — all listed CLI binaries must be in PATH
- `requires.anyBins` — at least one listed binary must exist
- `requires.env` — all listed env vars must be set
- `requires.config` — config file paths must exist
- `os` — platform must match (linux, darwin, win32)
- `enabled: false` in openclaw.json — force-disables a skill

## Adding a new skill

1. Create a folder: `skills/my-skill/`
2. Add `SKILL.md` with frontmatter and instructions
3. Rebuild the Docker image (skills are baked in at build time)

For development without rebuilding, override the workspace volume mount
to point at your local `.nekaiseagent/` directory.
