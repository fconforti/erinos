# Core

Sinatra REST API that powers ErinOS. Manages models, agents, tools, conversations, and messages. Persists everything to SQLite. Talks to Ollama for LLM inference via RubyLLM.

## Identity & auth

Channels identify callers via three HTTP headers:

| Header | Required | Example |
|--------|----------|---------|
| `X-Identity-Provider` | Yes | `cli`, `telegram`, `tailscale` |
| `X-Identity-UID` | Yes | `dev`, `12345678` |
| `X-Identity-Name` | No | `Developer`, `Jane Doe` |

On first contact, Core auto-provisions a User and Identity record (JIT). The first user ever created gets the `admin` role; subsequent users get `user`.

Conversations and messages endpoints require identity headers (401 without them). Model, agent, and tool endpoints are unauthenticated — they're management APIs.

## Endpoints

All responses are JSON. Port 4567.

### Conversations (scoped to current user)

```
POST   /conversations              Create conversation (optional: agent_id)
GET    /conversations/:id          Get conversation with messages
DELETE /conversations/:id          Delete conversation
```

### Messages (scoped to current user)

```
GET    /conversations/:cid/messages       List messages
POST   /conversations/:cid/messages       Send message, stream response (SSE)
```

The POST returns `text/event-stream`. Each frame is `data: {"content":"..."}`. The final frame includes `"done": true` and the full message object.

### Models

```
GET    /models          POST   /models
GET    /models/:id      PATCH  /models/:id      DELETE /models/:id
```

### Agents

```
GET    /agents          POST   /agents
GET    /agents/:id      PATCH  /agents/:id      DELETE /agents/:id
GET    /agents/default
```

### Tools

```
GET    /tools           POST   /tools
GET    /tools/:id       PATCH  /tools/:id       DELETE /tools/:id
```

### Agent–Tool assignments

```
GET    /agents/:id/tools
POST   /agents/:id/tools           Assign (body: {tool_id})
DELETE /agents/:id/tools/:tool_id  Remove
```

### Health

```
GET    /health          → {"status":"ok"}
```

## Gateway

The Gateway is the single entry point for channel interactions. It accepts a user and provides two operations:

- **create_conversation** — finds the requested agent (or the default) and creates a conversation owned by the user.
- **reply** — delegates to ChatService, which builds the full conversation context and calls the LLM.

Channels never talk to ChatService or ActiveRecord directly — everything goes through Gateway.

## ChatService

Handles the actual LLM interaction:

1. Persists the user message.
2. Creates a RubyLLM context configured with the model's Ollama API base.
3. Loads the agent's instructions and full conversation history.
4. Calls `chat.ask(content, &on_chunk)` — chunks stream back to the caller via a block.
5. Persists the assistant response.

## Schema

A **model** has many **agents**. An agent has many **tools** through the **agent_tools** join table. An agent has many **conversations**, and each conversation belongs to a **user**. A conversation has many **messages**. A user has many **identities** (one per provider).

Key constraints:
- `identities` has a unique index on `[provider, uid]` — one identity per provider per person.
- `agent_tools` has a unique index on `[agent_id, tool_id]`.
- Conversations belong to both an agent and a user.
- Messages have a `role` field: `user`, `assistant`, or `system`.

## Seeds

`rake db:seed` creates:

- A default Ollama model (`gpt-oss:120b-cloud`).
- A default agent ("Erin") with basic assistant instructions.
- A dev user with `admin` role and a `cli`/`dev` identity for CLI access.

## File layout

```
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
```

## Environment

| Variable | Default | Description |
|----------|---------|-------------|
| `RACK_ENV` | `development` | Rack environment |
