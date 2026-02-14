# ErinOS Skills

Curated OpenClaw skills, organized by risk tier. All disabled by default.

## Tiers

- **safe/** — No system access (reminders, notes, calendar, weather, timers)
- **moderate/** — Reads local data (file search, doc summary, log viewer)
- **elevated/** — Executes on host, sandboxed in Docker (shell, file management, system monitoring)

## Adding Skills

Each skill directory should contain:
- `skill.json` — OpenClaw skill definition
- `REVIEW.md` — Documents permissions, risks, and blast radius

Enable via: `erinos skill enable <name>`
