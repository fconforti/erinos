# CLAUDE.md

You are building **ErinOS**, a minimal, secure Arch Linux distro that boots into a local-first AI assistant powered by OpenClaw and Ollama. This is a real project, not a prototype. Write production-quality code and configs.

## Project Context

Read `README.md` first — it is the source of truth for architecture, design decisions, and scope. Everything below supplements it with implementation guidance.

## Core Principles

- **Opinionated, not configurable.** Make choices. Don't offer alternatives where a best practice exists.
- **Security by default.** Every file you create should assume hostile network conditions. Loopback-only services, key-only SSH, LUKS required, firewall deny-all.
- **Local-first.** Ollama is the default model provider. Cloud is opt-in, configured during onboarding.
- **Token-aware.** OpenClaw's context window overhead is the primary operational constraint for local models. Every config decision should minimize prompt token usage.
- **Appliance UX.** The target user plugs in hardware, boots from USB, and follows a terminal wizard. No manual config file editing.

## Architecture

Four systemd-managed services:
1. **Ollama** — `127.0.0.1:11434`, local LLM inference
2. **OpenClaw Gateway** — Node.js agent, message routing, skill invocation
3. **Docker** — sandbox for all OpenClaw tool execution (no network, read-only root, scoped workspace)
4. **Tailscale** — WireGuard mesh VPN, SSH only on `tailscale0`

## Tech Stack

- **Base:** Arch Linux (minimal), archiso for ISO generation
- **Init:** systemd (services, timers, resolved)
- **Networking:** NetworkManager (nmtui for WiFi), firewalld, Tailscale
- **Runtime:** Node.js 22 LTS (nodejs-lts-iron), npm, Docker
- **AI:** Ollama, OpenClaw
- **Onboarding TUI:** gum (Charm), qrencode (terminal QR codes)
- **Utilities:** htop, tmux, neovim, git, curl, wget

## Repository Structure

Follow this layout exactly:

```
erinos/
├── README.md
├── LICENSE                     # MIT
├── CLAUDE.md                   # This file
├── Makefile
├── build.sh                    # Wrapper around mkarchiso
│
├── archiso-profile/            # Customized releng profile
│   ├── profiledef.sh
│   ├── packages.x86_64         # All packages for the ISO
│   ├── pacman.conf
│   └── airootfs/               # Files baked into the live/installed system
│       ├── etc/
│       │   ├── ssh/sshd_config.d/hardened.conf
│       │   ├── firewalld/zones/public.xml
│       │   ├── systemd/resolved.conf.d/dot.conf
│       │   ├── systemd/system/ollama.service
│       │   ├── systemd/system/erinos-onboard.service
│       │   ├── systemd/system/erinos-update.timer
│       │   ├── systemd/system/erinos-update.service
│       │   ├── docker/daemon.json
│       │   ├── profile.d/erinos-motd.sh
│       │   └── skel/.bashrc
│       ├── usr/local/bin/
│       │   ├── erinos           # CLI entrypoint
│       │   └── erinos-onboard   # First-boot wizard
│       └── root/customize_airootfs.sh
│
├── config/
│   ├── openclaw.json.template   # OpenClaw config with placeholders
│   ├── AGENTS.md                # Lean — few lines, saves tokens
│   ├── SOUL.md                  # Lean
│   └── USER.md                  # Lean
│
├── skills/
│   ├── safe/                    # No system access
│   ├── moderate/                # Reads local data
│   ├── elevated/                # Executes on host (sandboxed)
│   └── README.md
│
├── scripts/
│   ├── onboard.sh               # Onboarding wizard logic
│   ├── erinos-cli.sh            # CLI subcommand dispatcher
│   ├── detect-hardware.sh       # RAM/GPU/VRAM detection
│   ├── install.sh               # Disk installer (LUKS + base)
│   └── update.sh                # Daily update logic
│
├── tests/
│
└── docs/
    ├── BUILDING.md
    ├── ONBOARDING.md
    ├── SECURITY.md
    ├── CONTEXT-WINDOW.md
    └── SKILLS.md
```

## Key Implementation Details

### archiso Profile

Start from the `releng` profile (`/usr/share/archiso/configs/releng/`). Customize:
- `packages.x86_64`: add all required packages
- `airootfs/`: overlay with hardened configs and ErinOS scripts
- `profiledef.sh`: set iso label, publisher, etc.

### Security Configs

**sshd_config.d/hardened.conf:**
```
PasswordAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
ListenAddress 0.0.0.0
# Firewall restricts SSH to tailscale0 — sshd doesn't need to know
```

**firewalld/zones/public.xml:** Default zone for physical interfaces. No open ports.

Create a `tailscale.xml` zone that allows SSH, assigned to the `tailscale0` interface.

**resolved.conf.d/dot.conf:**
```
[Resolve]
DNS=1.1.1.1#cloudflare-dns.com
DNSOverTLS=yes
```

**docker/daemon.json:** Restrict Docker defaults (no ICC, userland proxy off if possible).

### Security Audit

ErinOS uses OpenClaw's built-in `openclaw security audit` command. Do NOT build a custom audit system.

**Triggers:**
- After every update (`erinos-update.service` runs `openclaw security audit --deep`)
- On boot: lightweight check only — Tailscale status, LUKS mount verification, Docker socket permissions
- After config changes: `erinos config` subcommands should run `openclaw security audit` (quick mode) before applying

**NOT triggered:**
- No daily cron. Single-user appliance behind Tailscale + LUKS doesn't need it. Post-update and on-boot cover the real risk surface.

**Output:**
- Audit findings must be surfaced through the messaging assistant, not buried in logs.
- If `openclaw security audit --deep` returns findings after an update, write a flag file (e.g., `/var/lib/erinos/audit-findings`) containing the output. The OpenClaw system prompt should instruct the agent to check for this file and proactively report findings.
- After the user acknowledges, delete the flag file.

**What the audit checks** (from OpenClaw docs):
- Inbound access policies (DM/group policies, allowlists)
- Tool blast radius (elevated tools + open rooms)
- Network exposure (Gateway bind/auth, Tailscale)
- Disk hygiene (permissions, symlinks, config includes)
- Plugin allowlists
- Policy drift/misconfig
- Model hygiene

### Boot Health Check

`erinos-health.service` runs at boot (After=network-online.target tailscaled.service). It verifies:
- LUKS root is mounted encrypted (`cryptsetup status`)
- Tailscale is up and authenticated (`tailscale status`)
- Docker socket permissions are correct (`stat /var/run/docker.sock`)
- OpenClaw state directory permissions are 700 (`stat ~/.openclaw`)

If any check fails, writes to `/var/lib/erinos/boot-health` for the assistant to report. This is NOT `openclaw security audit` — it's a fast, ErinOS-specific sanity check that runs before OpenClaw is even started.

### OpenClaw Config Template

Use `config/openclaw.json.template` with placeholders like `__SELECTED_MODEL__`, `__AUTH_TOKEN__`, `__CHANNEL_CONFIG__` that get replaced during onboarding.

Critical defaults:
- `agents.defaults.compaction.mode`: `"safeguard"`
- `agents.defaults.compaction.reserveTokens`: `8000`
- `agents.defaults.bootstrapMaxChars`: `5000`
- `agents.defaults.sandbox.mode`: `"all"`
- `agents.defaults.sandbox.docker.network`: `"none"`
- `agents.defaults.sandbox.docker.readOnlyRoot`: `true`
- `skills.defaults.enabled`: `false`
- `gateway.bind`: `"loopback"`

### Onboarding Wizard (erinos-onboard)

6 steps, implemented with `gum` for prompts and `qrencode -t ANSI` for terminal QR codes:

1. **Network** — launch `nmtui` for WiFi/Ethernet config
2. **Tailscale** — install + start tailscaled, get login URL, display as QR code, wait for auth
3. **Models** — run `detect-hardware.sh`, suggest models, let user pick local/cloud/hybrid, configure model routing (light model for routine tasks, heavy model for complex tasks)
4. **Messaging** — select channel (Telegram/Discord/WhatsApp/Slack/Signal), display setup instructions as QR code where applicable
5. **Skills** — show checklist grouped by risk tier (safe/moderate/elevated), all off by default
6. **Verify & Start** — run `erinos doctor`, start all services, print success message

### erinos CLI

Single bash script at `/usr/local/bin/erinos` that dispatches to subcommands:
- `status`, `doctor`, `model {list,pull,use,route}`, `skill {list,enable,disable}`, `channel add`, `sandbox {status,shell}`, `update`, `logs [--ollama]`, `reset`

### Hardware Detection (detect-hardware.sh)

```bash
# RAM
free -g | awk '/Mem:/{print $2}'

# GPU vendor
lspci | grep -i 'vga\|3d\|display'

# NVIDIA VRAM
nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null

# AMD VRAM (unified memory on APUs like Ryzen AI Max)
# Check /sys/class/drm/card*/device/mem_info_vram_total
```

Map to model suggestions per the table in README.md.

### Installer (install.sh)

Handles: disk selection → GPT partitioning → LUKS encryption (required, no opt-out) → mkfs → pacstrap → fstab → GRUB install with LUKS unlock → create `erin` user → copy ErinOS configs → enable services → reboot.

### Update Timer

`erinos-update.timer` fires daily. `erinos-update.service` runs `update.sh` which:
- `pacman -Syu --noconfirm`
- Updates OpenClaw (npm or git pull, TBD based on OpenClaw's update mechanism)
- Updates Ollama (`ollama update` or re-download)
- Runs `openclaw security audit --deep` post-update to catch config drift or exposure regressions
- Checks if kernel was updated → writes flag file for reboot notification on next login
- Writes audit results to `/var/log/erinos-update.log`; if findings are non-empty, writes a flag file that the assistant reads on next conversation to proactively inform the user

## Coding Standards

- **Shell scripts:** Use `#!/usr/bin/env bash`, `set -euo pipefail`. Quote all variables. Use functions. Add brief comments for non-obvious logic.
- **Configs:** Use the simplest format that works (INI for systemd, JSON for OpenClaw, XML for firewalld — match what each tool expects).
- **No Python.** Everything is bash, Node.js (OpenClaw), or Go (gum binary).
- **Test with:** `shellcheck` for all bash scripts.

## What NOT to Build

- No web UI. CLI and messaging only.
- No custom kernel. Use stock `linux` package.
- No multi-user support. Single `erin` user.
- No ARM/aarch64 support (yet).
- No Wayland/X11/desktop environment.
- No systemd-boot. Use GRUB (needed for LUKS unlock).

## First Task

Bootstrap the repository structure. Create all directories, placeholder files, the archiso profile based on releng, `packages.x86_64` with the full package list, all security config files, the `build.sh` wrapper, and the `erinos` CLI skeleton with subcommand dispatch. Make everything syntactically valid and shellcheck-clean. Don't stub — write real implementations where the scope is clear (security configs, systemd units, firewall zones, build script).