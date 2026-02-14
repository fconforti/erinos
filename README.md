# ErinOS

A minimal, secure Arch Linux distro that boots into a local-first AI assistant powered by [OpenClaw](https://openclaw.ai) and [Ollama](https://ollama.com).

---

## Why ErinOS

Personal AI assistants are becoming infrastructure. An always-on agent that manages your calendar, triages your inbox, drafts messages, executes tasks, and remembers context across conversations. The building blocks are here: open-source agent frameworks, capable local models, cheap hardware. But setting this up well — privately, securely, reliably — is still unreasonably hard.

Most people running OpenClaw today are doing it on their daily-driver Mac or a hastily configured VPS. API keys in plaintext. SSH wide open. No disk encryption. No sandboxing. The agent has root access and an open network port. It works, but it's a liability.

ErinOS is a dedicated, hardened, single-purpose appliance for running a personal AI assistant — the same way you'd run a router or a NAS. It boots encrypted, connects to your messaging apps, runs inference locally, sandboxes every tool call, and stays updated automatically. Security and privacy are the default state, not an afterthought.

This is an opinionated distro. LUKS encryption is required. Tailscale is the remote access layer. All skills are disabled until you opt in. The firewall blocks everything by default. Context windows are tuned for local models out of the box. If you disagree with a decision, the source is MIT-licensed — fork it.

---

## How It Works

Flash ErinOS to a mini-PC, NUC, old laptop, or any x86_64 machine. It boots to a terminal, walks you through a setup wizard, and starts serving your AI assistant. You interact with it through the messaging apps you already use — Telegram, WhatsApp, Discord, Slack, Signal — not through the machine itself. The machine is the engine; your phone is the steering wheel.

---

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                           ErinOS                             │
│                                                              │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────────┐  │
│  │    Ollama    │◄──│   OpenClaw   │──►│    Messaging     │  │
│  │   (local     │   │   Gateway    │   │    Channels      │  │
│  │    LLM)      │   │  (Node.js)   │   │ (WhatsApp, …)    │  │
│  └──────────────┘   └──────┬───────┘   └──────────────────┘  │
│                            │                                 │
│  ┌──────────────┐   ┌──────┴───────┐   ┌──────────────────┐  │
│  │  Cloud APIs  │   │    Docker    │   │    Tailscale     │  │
│  │  (opt-in)    │   │   Sandbox    │   │  (remote access) │  │
│  │              │   │   (skills)   │   │                  │  │
│  └──────────────┘   └──────────────┘   └──────────────────┘  │
│                                                              │
├──────────────────────────────────────────────────────────────┤
│  Arch Linux (minimal) · LUKS full-disk encryption            │
│  systemd · NetworkManager · Docker · Node 22 · firewalld     │
└──────────────────────────────────────────────────────────────┘
```

Four runtime components, all managed by systemd:

1. **Ollama** — local LLM inference on `127.0.0.1:11434`, never network-exposed
2. **OpenClaw Gateway** — agent orchestration, message routing, model selection, skill invocation
3. **Docker** — sandboxed execution for all skill tool calls
4. **Tailscale** — encrypted WireGuard mesh VPN for remote SSH access

---

## Models

ErinOS is local-first. The onboarding wizard detects hardware (RAM, GPU, VRAM) and recommends models that fit. Ollama is installed during first boot.

| System | Suggested Model | Size |
|---|---|---|
| 8 GB RAM, no GPU | `phi3:mini` (3.8B) | ~2 GB |
| 16 GB RAM, no GPU | `llama3.2:3b` or `qwen3:8b` | ~4–5 GB |
| 16 GB RAM, 8+ GB VRAM | `qwen3:8b` (GPU) | ~5 GB |
| 32+ GB RAM, 16+ GB VRAM | `qwen3:30b-coder` or `llama3.3` | ~18 GB |

### Cloud models

For hardware that can't run a capable local model, or when you need higher-quality reasoning, the wizard supports cloud providers as an alternative or complement: Anthropic, OpenAI, Google, Ollama Cloud, and others. During onboarding, a QR code links to the provider's API key page — scan on your phone, create a key, paste it back.

### Model routing

OpenClaw supports assigning different models to different tasks. ErinOS configures this during onboarding: lighter models handle simple, frequent operations (cron jobs, reminders, quick lookups) while more capable models handle complex tasks (research, drafting, multi-step reasoning). On a local-only setup this means a small model for routine work and a larger one for heavy lifting. On a hybrid setup, local handles the lightweight tasks and cloud handles the rest.

The wizard guides you through these defaults. Everything can be changed later via `erinos model`.

---

## Security & Privacy

All hardening is baked into the ISO. Every installation starts secure.

**LUKS full-disk encryption** — Required. Passphrase set during install, prompted at every boot. Protects conversations, models, API keys — everything at rest.

**Firewall** — All inbound traffic blocked on physical interfaces. SSH allowed only over Tailscale (`tailscale0`). Ollama and OpenClaw bind to loopback.

**SSH** — Key-only auth, no root login, no passwords.

**DNS** — DNS-over-TLS via `systemd-resolved` (Cloudflare `1.1.1.1`).

**Sandboxing** — All OpenClaw tool calls execute inside Docker containers with no network access, read-only root filesystem, and scoped workspace mounts. The gateway runs on the host; everything the LLM triggers runs in the sandbox.

**Updates** — Daily systemd timer: `pacman -Syu`, `openclaw update`, Ollama update. Kernel updates flagged for manual reboot. Post-update security audit via `openclaw security audit --deep` catches config drift and exposure regressions. Findings are surfaced through the assistant on next conversation.

---

## Remote Access

ErinOS uses [Tailscale](https://tailscale.com) for remote access. During onboarding, the wizard displays a login URL as a QR code in the terminal. Scan it, authenticate in your browser, and the machine joins your tailnet with a stable private IP (`100.x.y.z`). SSH from any device on your tailnet — laptop, phone, anywhere.

SSH is only available over `tailscale0`. Physical interfaces are fully locked down. No ports, no static IPs, no key management.

Tailscale's free tier supports up to 3 users and 100 devices. Traffic is end-to-end encrypted via WireGuard; the coordination server sees connection metadata only. For self-hosters, [Headscale](https://github.com/juanfont/headscale) is a drop-in replacement — pass `--login-server` during setup.

---

## Context Window Optimization

OpenClaw's system prompt consumes 20,000–40,000 tokens before your first message (agent instructions, tool schemas, workspace files). Cloud models with 200K+ context absorb this easily. Local models with 8K–32K usable tokens hit overflow after 2–3 exchanges.

ErinOS solves this with aggressive defaults: stripped workspace files (`bootstrapMaxChars: 5000` vs default 20,000), all skills disabled (each adds tool schemas to the prompt), and early conversation compaction (`reserveTokens: 8000`). Model recommendations factor in OpenClaw's overhead — only models with enough usable context are suggested.

See `docs/CONTEXT-WINDOW.md` for details.

---

## Onboarding

On first boot, the wizard walks through setup. QR codes are rendered directly in the terminal via `qrencode` whenever a URL needs to be visited — Tailscale login, cloud API key pages, messaging bot setup.

```
┌──────────────────────────────────────────────────┐
│            Welcome to ErinOS v0.1                │
│                                                  │
│  1. Network         → WiFi/Ethernet via nmtui    │
│  2. Tailscale       → QR code → scan to auth     │
│  3. Models          → Hardware detection         │
│     → Local model selection (Ollama)             │
│     → Cloud provider setup (optional)            │
│     → Task routing (light vs heavy models)       │
│  4. Messaging       → Telegram/Discord/WhatsApp  │
│  5. Skills          → Opt-in by risk level       │
│  6. Verify & Start  → erinos doctor → go         │
│                                                  │
│  ✓ Your assistant is running. Send it a message. │
└──────────────────────────────────────────────────┘
```

The wizard is built with [gum](https://github.com/charmbracelet/gum) (terminal prompts) and `qrencode` (inline QR codes).

---

## Skills

ErinOS ships curated OpenClaw skills, all disabled by default. Enabled during onboarding or later via `erinos skill`.

**Safe** (no system access): reminders, notes, calendar, weather, timers · **Moderate** (reads local data): file search, doc summary, log viewer · **Elevated** (executes on host): shell, file management, system monitoring

Each skill includes a `REVIEW.md` documenting permissions and risks. Skills that run with elevated access are sandboxed in Docker.

---

## CLI

```bash
erinos status              # Services, model, channels, context usage
erinos doctor              # Health check

erinos model list          # Installed and available models
erinos model pull <name>   # Download a model
erinos model use <name>    # Switch active model
erinos model route         # Configure task-based model routing

erinos skill list          # Skills and status
erinos skill enable <name> # Enable a skill
erinos skill disable <name># Disable a skill

erinos channel add         # Connect a messaging channel

erinos sandbox status      # Docker sandbox state
erinos sandbox shell       # Shell into sandbox

erinos update              # System + OpenClaw + Ollama
erinos logs [--ollama]     # Tail logs

erinos reset               # Factory reset
```

---

## Development

### Native Arch Linux (recommended)

The simplest path. An x86_64 machine running Arch — the same hardware ErinOS targets. `archiso` runs natively, QEMU uses KVM for near-native ISO testing, and you can validate the full stack including GPU inference.

```bash
# Install dependencies
sudo pacman -Syu --noconfirm archiso git base-devel qemu-desktop edk2-ovmf

# Build
cd erinos
sudo ./build.sh
# → out/erinos-<date>-x86_64.iso

# Test
qemu-img create -f qcow2 /tmp/erinos-test.qcow2 40G
qemu-system-x86_64 \
  -enable-kvm -m 8192 -smp 4 \
  -drive file=/tmp/erinos-test.qcow2,if=virtio \
  -cdrom out/erinos-*.iso \
  -boot d -nic user,hostfwd=tcp::2222-:22
```

### macOS (fallback)

`archiso` requires Arch Linux. On macOS, use a Docker container with x86_64 emulation:

```bash
docker run --platform linux/amd64 -it --privileged \
  -v $(pwd):/erinos \
  archlinux:latest bash

# Inside the container
pacman -Syu --noconfirm archiso git base-devel
cd /erinos
./build.sh
```

Alternatively, [OrbStack](https://orbstack.dev) can create an x86_64 Arch VM via Rosetta:

```bash
orb create --arch amd64 arch erinos-build
orb shell -m erinos-build
sudo pacman -Syu --noconfirm archiso git base-devel qemu-desktop edk2-ovmf
cd /mnt/mac/path/to/erinos
sudo ./build.sh
```

Both approaches use Rosetta for x86_64 emulation. Builds are slower than native but functional.

### CI/CD

GitHub Actions with `archlinux:latest` container and `--privileged` for `mkarchiso`. Tagged releases build and upload the ISO as an artifact.

---

## Repository Structure

```
erinos/
├── archiso-profile/
│   ├── profiledef.sh
│   ├── packages.x86_64
│   ├── pacman.conf
│   └── airootfs/
│       ├── etc/
│       │   ├── ssh/sshd_config.d/hardened.conf
│       │   ├── firewalld/zones/public.xml
│       │   ├── systemd/resolved.conf.d/dot.conf
│       │   ├── systemd/system/{ollama,erinos-onboard}.service
│       │   ├── systemd/system/erinos-update.timer
│       │   └── docker/daemon.json
│       └── usr/local/bin/{erinos,erinos-onboard}
├── config/
│   ├── openclaw.json.template
│   ├── AGENTS.md
│   ├── SOUL.md
│   └── USER.md
├── skills/{safe,moderate,elevated}/
├── scripts/{onboard,erinos-cli,detect-hardware,install,update}.sh
├── tests/
└── docs/{BUILDING,ONBOARDING,SECURITY,CONTEXT-WINDOW,SKILLS}.md
```

---

## Design Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Architecture | x86_64 only | NVIDIA CUDA, target hardware is mini-PCs/NUCs/servers |
| Disk encryption | LUKS, required | AI assistant stores sensitive data |
| Remote access | Tailscale, required | QR-based auth, no key management, works everywhere |
| Models | Local-first, cloud opt-in | Privacy by default, cloud when hardware or task demands it |
| Model routing | Light + heavy models | Save resources on routine tasks, use capable models where it matters |
| Sandboxing | Docker (OpenClaw built-in) | No-network, read-only containers for all tool execution |
| Skills | All disabled by default | Each skill costs tokens and expands attack surface |
| Firewall | SSH only on tailscale0 | Physical interfaces fully locked down |
| Updates | Daily, automatic | Appliance should stay patched |
| Security audit | Post-update + on-boot | OpenClaw built-in; no daily cron — single-user appliance behind Tailscale doesn't need it |
| Context tuning | bootstrapMaxChars=5000 | Local models need aggressive optimization |
| Onboarding UX | QR codes in terminal | Scanning beats typing on a headless machine |
| Web UI | None | CLI-only, smaller attack surface |
| License | MIT | Permissive, compatible with OpenClaw |

---

## License

MIT — see [LICENSE](./LICENSE).