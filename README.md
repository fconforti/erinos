# ErinOS

Local-first AI assistant powered by Ollama. Runs as a set of Docker containers: an API core, an LLM inference server, and a management CLI.

## Architecture

```
compose.yml          # Orchestrates all services
core/                # Sinatra API — models, agents, tools (SQLite)
channels/
  cli/               # Thor CLI — management commands via `erin`
```

### Services

| Service       | Role                                    | Runs with `up`? |
|---------------|-----------------------------------------|-----------------|
| **core**      | REST API (Sinatra + Puma, port 4567)    | Yes             |
| **ollama**    | LLM inference server (port 11434)       | Yes             |
| **ollama-init** | One-shot model pull, then exits       | Yes             |
| **cli**       | Management CLI (`erin`), runs ad-hoc    | No (profiled)   |

## Quick Start

```bash
# Start all services
docker compose up -d

# Sign in to Ollama for cloud models (first time only)
docker compose exec ollama ollama login

# Wait for core to be healthy, then use the CLI
erin agents default
erin models list
```

## CLI Setup

Build the CLI container:

```bash
docker compose build cli
```

Add this alias to `~/.zshrc`:

```bash
alias erin='docker compose -f /path/to/erinos/compose.yml run --rm cli'
```

Then reload your shell. See [channels/cli/README.md](channels/cli/README.md) for the full command reference.

## Development

Core must be running for the CLI to work:

```bash
docker compose up -d          # start core + ollama
docker compose up --build     # rebuild and start
docker compose run core rake console   # Rails-style console
```

### Project Layout

```
core/
  api.rb                      # Main Sinatra app, mounts all APIs
  api/                        # Route handlers (models, agents, tools, agent_tools)
  entities/                   # ActiveRecord models
  db/migrate/                 # Schema migrations
  db/seeds.rb                 # Default agent + model seed
  config/application.rb       # Bundler, Zeitwerk, DB connection

channels/cli/
  cli.rb                      # Entry point (Erin < Thor)
  core_client.rb              # Faraday HTTP client for Core API
  commands/                   # Thor subcommands (models, agents, tools)
```
