# Erin CLI

Management CLI for ErinOS Core. Manage models, agents, and tools from the terminal.

## Setup

Build the CLI container:

```bash
docker compose build cli
```

Add this alias to your `~/.zshrc` (or `~/.bashrc`):

```bash
alias erin='docker compose -f /path/to/erinos/compose.yml run --rm cli'
```

Reload your shell (`source ~/.zshrc`) and you're ready.

## Prerequisites

Core must be running before using the CLI:

```bash
docker compose up -d core
```

If Core is unreachable, the CLI prints an error and exits.

## Commands

### Models

```bash
erin models list
erin models show 1
erin models create --provider ollama --name llama3
erin models create --provider ollama --name llama3 --credentials api_key:sk-123
erin models update 1 --name llama3-updated
erin models delete 1
```

### Agents

```bash
erin agents list
erin agents show 1
erin agents default
erin agents create --model-id 1 --name "My Agent" --instructions "Be helpful."
erin agents create -m 1 -n "My Agent" -i "Be helpful." --default
erin agents update 1 --name "New Name"
erin agents delete 1
```

Agent-tool assignments:

```bash
erin agents tools 1              # list tools assigned to agent 1
erin agents assign-tool 1 --tool-id 2
erin agents remove-tool 1 --tool-id 2
```

### Tools

```bash
erin tools list
erin tools show 1
erin tools create --name web_search
erin tools update 1 --name web_browse
erin tools delete 1
```

### Help

```bash
erin help
erin models help
erin agents help create
```

## Architecture

```
channels/cli/
  cli.rb              # Entry point — Erin < Thor, dispatches subcommands
  core_client.rb      # Faraday HTTP client, talks to Core API
  commands/
    base.rb           # Shared base class (client, output helpers)
    models.rb         # Models subcommand
    agents.rb         # Agents subcommand (includes tool assignments)
    tools.rb          # Tools subcommand
```

The CLI runs as an ad-hoc Docker container (`profiles: [cli]`) and talks to Core over the internal Docker network. It is not started by `docker compose up`.

## Environment

| Variable   | Default              | Description       |
|------------|----------------------|-------------------|
| `CORE_URL` | `http://core:4567`   | Core API base URL |
