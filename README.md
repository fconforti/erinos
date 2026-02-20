# ErinOS

Local-first AI assistant powered by Ollama. Runs as a set of Docker containers: an API core, an LLM inference server, and pluggable channels (CLI, Telegram).

## Architecture

The system is composed of five Docker services. Channels (CLI, Telegram) send HTTP requests to Core, which resolves the caller's identity, routes through the Gateway, and delegates to ChatService for LLM interactions via Ollama. All state lives in a single SQLite database.

### Services

| Service         | Role                                  | Runs with `up`? |
|-----------------|---------------------------------------|-----------------|
| **core**        | REST API (Sinatra + Puma, port 4567)  | Yes             |
| **ollama**      | LLM inference server (port 11434)     | Yes             |
| **ollama-init** | One-shot model pull, then exits       | Yes             |
| **telegram**    | Telegram bot (streaming chat)         | Yes             |
| **cli**         | Management CLI, runs ad-hoc           | No (profiled)   |

### Data flow

1. A channel (CLI, Telegram) sends an HTTP request to Core with `X-Identity-*` headers.
2. Core resolves the identity → user, scopes the request to that user's conversations.
3. For chat messages, the Gateway delegates to ChatService, which builds a RubyLLM chat with the conversation's agent instructions and full message history.
4. ChatService calls Ollama via RubyLLM. Chunks stream back through SSE to the channel.
5. The final assistant message is persisted to SQLite.

## Core API

Sinatra app at port 4567. All responses are JSON except SSE streaming endpoints.

### Identity & auth

Channels identify themselves via three HTTP headers:

| Header | Required | Example |
|--------|----------|---------|
| `X-Identity-Provider` | Yes | `cli`, `telegram`, `tailscale` |
| `X-Identity-UID` | Yes | `dev`, `12345678` |
| `X-Identity-Name` | No | `Developer`, `Jane Doe` |

On first contact, Core auto-provisions a User and Identity record (JIT). The first user ever created gets the `admin` role; subsequent users get `user`.

Conversations and messages endpoints require identity headers (401 without them). Model, agent, and tool endpoints are unauthenticated — they're management APIs used by the CLI.

### Endpoints

**Conversations** (scoped to current user)

```
POST   /conversations              Create conversation (optional: agent_id)
GET    /conversations/:id          Get conversation with messages
DELETE /conversations/:id          Delete conversation
```

**Messages** (scoped to current user)

```
GET    /conversations/:cid/messages       List messages
POST   /conversations/:cid/messages       Send message, stream response (SSE)
```

The POST returns `text/event-stream`. Each frame is `data: {"content":"..."}`. The final frame includes `"done": true` and the full message object.

**Models**

```
GET    /models          POST   /models
GET    /models/:id      PATCH  /models/:id      DELETE /models/:id
```

**Agents**

```
GET    /agents          POST   /agents
GET    /agents/:id      PATCH  /agents/:id      DELETE /agents/:id
GET    /agents/default
```

**Tools**

```
GET    /tools           POST   /tools
GET    /tools/:id       PATCH  /tools/:id       DELETE /tools/:id
```

**Agent–Tool assignments**

```
GET    /agents/:id/tools
POST   /agents/:id/tools           Assign (body: {tool_id})
DELETE /agents/:id/tools/:tool_id  Remove
```

**Health**

```
GET    /health          → {"status":"ok"}
```

### Gateway

The Gateway is the single entry point for channel interactions. It accepts a user and provides two operations:

- **create_conversation** — finds the requested agent (or the default) and creates a conversation owned by the user.
- **reply** — delegates to ChatService, which builds the full conversation context and calls the LLM.

Channels never talk to ChatService or ActiveRecord directly — everything goes through Gateway.

### ChatService

Handles the actual LLM interaction:

1. Persists the user message.
2. Creates a RubyLLM context configured with the model's Ollama API base.
3. Loads the agent's instructions and full conversation history.
4. Calls `chat.ask(content, &on_chunk)` — chunks stream back to the caller via a block.
5. Persists the assistant response.

### Schema

A **model** has many **agents**. An agent has many **tools** through the **agent_tools** join table. An agent has many **conversations**, and each conversation belongs to a **user**. A conversation has many **messages**. A user has many **identities** (one per provider).

Key constraints:
- `identities` has a unique index on `[provider, uid]` — one identity per provider per person.
- `agent_tools` has a unique index on `[agent_id, tool_id]`.
- Conversations belong to both an agent and a user.
- Messages have a `role` field: `user`, `assistant`, or `system`.

## Channels

### CLI

Thor-based management CLI. Runs as an ad-hoc Docker container.

```bash
# Build (once, or after code changes)
docker compose build cli

# Run commands
docker compose run --rm cli models list
docker compose run --rm cli agents default
docker compose run --rm cli chat
```

Add a shell alias for convenience:

```bash
alias erin='docker compose -f /path/to/erinos/compose.yml run --rm cli'
```

Then: `erin chat`, `erin models list`, `erin agents show 1`, etc.

The CLI sends a fixed dev identity (`cli`/`dev`/`Developer`). See [channels/cli/README.md](channels/cli/README.md) for the full command reference.

### Telegram

Long-running bot that streams responses with real-time message editing.

1. Message [@BotFather](https://t.me/BotFather) on Telegram, send `/newbot`.
2. Copy the API token into `.env`:

```
TELEGRAM_BOT_TOKEN=123456789:ABCdefGHIjklMNOpqrSTUvwxYZ
```

3. Start services:

```bash
docker compose up -d
```

Each Telegram user gets their own ErinOS identity (provider `telegram`, uid from Telegram user ID). Conversations are per-chat. Send `/start` or `/new` to begin a fresh conversation.

### Adding a new channel

A channel is any process that talks to Core over HTTP. To add one:

1. Create an `ErinosClient` with the appropriate `X-Identity-*` headers for the channel's users.
2. `POST /conversations` to start a conversation.
3. `POST /conversations/:id/messages` with `{content: "..."}` and handle the SSE stream.
4. Add a Dockerfile and a service entry in `compose.yml`.

## Quick Start

```bash
# Set Telegram token (optional, only if you want the Telegram channel)
echo 'TELEGRAM_BOT_TOKEN=your-token' > .env

# Start all services (pulls Ollama model on first run)
docker compose up -d

# Sign in to Ollama for cloud models (first time only)
docker compose exec ollama ollama login

# Seed the database
docker compose exec core rake db:seed

# Chat via CLI
docker compose build cli
docker compose run --rm cli chat
```

## Development

```bash
docker compose up -d              # Start core + ollama
docker compose up -d --build      # Rebuild and start
docker compose exec core rake db:reset    # Drop, migrate, seed
docker compose run core rake console      # Rails-style console
docker compose logs -f core               # Tail core logs
```

### Project layout

```
compose.yml                           Docker Compose orchestration

core/
  api.rb                              Main Sinatra app, mounts all route modules
  api/
    base.rb                           BaseAPI — current_user, json_body helpers
    models.rb agents.rb tools.rb      CRUD endpoints
    agent_tools.rb                    Agent–tool assignment endpoints
    conversations.rb messages.rb      Chat endpoints (scoped to user)
  entities/
    user.rb identity.rb               Multi-user identity system
    model.rb agent.rb tool.rb         AI configuration entities
    agent_tool.rb                     Join table entity
    conversation.rb message.rb        Chat entities
  services/
    gateway.rb                        Single entry point for channel interactions
    chat_service.rb                   LLM interaction via RubyLLM
  db/
    migrate/                          ActiveRecord migrations (SQLite)
    seeds.rb                          Default model, agent, and dev user
  config/
    application.rb                    Bundler, Zeitwerk autoloader, DB connection

gems/erinos-client/
  lib/erinos_client.rb                Shared Faraday/Net::HTTP client for Core API

channels/cli/
  cli.rb                              Entry point (Thor)
  commands/                           Subcommands: chat, models, agents, tools

channels/telegram/
  bot.rb                              Telegram bot with SSE streaming
```
