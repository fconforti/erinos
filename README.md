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
2. Core resolves the identity to a user and scopes the request to that user's conversations.
3. For chat messages, the Gateway delegates to ChatService, which builds a RubyLLM chat with the conversation's agent instructions and full message history.
4. ChatService calls Ollama via RubyLLM. Chunks stream back through SSE to the channel.
5. The final assistant message is persisted to SQLite.

## Components

- [**Core**](core/README.md) — REST API, identity/auth, Gateway, ChatService, schema, and endpoints.
- [**CLI channel**](channels/cli/README.md) — Thor-based management CLI and interactive chat.
- [**Telegram channel**](channels/telegram/README.md) — Telegram bot with streaming responses.

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
core/                                 REST API (see core/README.md)
gems/erinos-client/                   Shared HTTP client gem for Core API
channels/cli/                         Management CLI (see channels/cli/README.md)
channels/telegram/                    Telegram bot (see channels/telegram/README.md)
```
