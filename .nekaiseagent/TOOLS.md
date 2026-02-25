# TOOLS.md - Local Notes

This file describes environment-specific details the agent needs to know.

## Building Data

Building data is stored at `/home/`. Each subfolder represents one building:

```
/home/
├── building-a/     ← CSV, PDF, logs, etc.
├── building-b/
└── ...
```

Use `/home/` as the default working location for all building-related tasks unless told otherwise.

When a user asks about "their buildings" or "building data", look in this directory first.

User-specific knowledge (known buildings, preferences, learned patterns) is stored in `/.opennekaise/memory/user.md`. Read it at session start for context.

---

Add whatever helps you do your job. This is your cheat sheet.
