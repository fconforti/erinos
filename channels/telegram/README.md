# Telegram Channel

Long-running Telegram bot for ErinOS. Streams responses with real-time message editing.

## Setup

1. Message [@BotFather](https://t.me/BotFather) on Telegram, send `/newbot` and follow the prompts.
2. Copy the API token into `.env` at the project root:

```
TELEGRAM_BOT_TOKEN=123456789:ABCdefGHIjklMNOpqrSTUvwxYZ
```

3. Start services:

```bash
docker compose up -d
```

The bot starts automatically with `docker compose up`. If you already have a bot, send `/mybots` to @BotFather, select your bot, and tap **API Token** to reveal it.

## Identity

Each Telegram user is mapped to an ErinOS user automatically. The bot sends identity headers to Core on every request:

- **Provider:** `telegram`
- **UID:** Telegram user ID (numeric, as string)
- **Name:** First name + last name from the Telegram profile

On first message, Core creates a User and Identity record for the sender.

## Commands

- `/start` or `/new` — start a fresh conversation.
- Any other text — send a message to the current conversation. If no conversation exists, one is created automatically.

## Streaming

The bot streams the LLM response in real time by editing the Telegram message as chunks arrive. Edits are rate-limited to one per second to stay within Telegram's API limits. A final edit sends the complete response.

## File layout

```
bot.rb              Entry point — connects to Telegram, listens for messages
Dockerfile          Ruby 3.4 Alpine image
Gemfile             Dependencies: telegram-bot-ruby, erinos-client
```

## Environment

| Variable | Default | Description |
|----------|---------|-------------|
| `CORE_URL` | `http://core:4567` | Core API base URL |
| `TELEGRAM_BOT_TOKEN` | (required) | Bot token from @BotFather |
