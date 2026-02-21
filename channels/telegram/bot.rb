# frozen_string_literal: true

$stdout.sync = true

require "telegram/bot"
require "erinos_client"
require "logger"

LOGGER = Logger.new($stdout, progname: "telegram-bot")
TOKEN  = ENV.fetch("TELEGRAM_BOT_TOKEN")

clients       = {} # user_id → ErinosClient
conversations = {} # chat_id → conversation_id

def client_for(from, clients)
  clients[from.id] ||= ErinosClient.new(headers: {
    "X-Identity-Provider" => "telegram",
    "X-Identity-UID" => from.id.to_s,
    "X-Identity-Name" => [from.first_name, from.last_name].compact.join(" "),
    "X-Identity-Timezone" => "UTC"
  })
end

# Minimum seconds between message edits (Telegram rate limit).
EDIT_INTERVAL = 1.0

def send_text(bot, chat_id, text)
  bot.api.send_message(chat_id: chat_id, text: text)
end

def ensure_conversation(client, conversations, chat_id)
  return conversations[chat_id] if conversations.key?(chat_id)

  conv = client.post("/conversations", {})
  conversations[chat_id] = conv["id"]
end

def stream_response(bot, client, chat_id, conversation_id, text)
  bot.api.send_chat_action(chat_id: chat_id, action: "typing")

  message_id   = nil
  buffer       = +""
  last_edit_at = 0.0

  client.post_sse("/conversations/#{conversation_id}/messages", { content: text }) do |data|
    if data["content"]
      buffer << data["content"]

      now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      if !buffer.empty? && now - last_edit_at >= EDIT_INTERVAL
        if message_id
          bot.api.edit_message_text(chat_id: chat_id, message_id: message_id, text: buffer)
        else
          msg = bot.api.send_message(chat_id: chat_id, text: buffer)
          message_id = msg.message_id
        end
        last_edit_at = now
      end
    elsif data["error"]
      buffer << "\n\nError: #{data["error"]}"
    end
  end

  # Final update with complete text
  if message_id
    bot.api.edit_message_text(chat_id: chat_id, message_id: message_id, text: buffer)
  elsif buffer.empty?
    send_text(bot, chat_id, "(empty response)")
  else
    send_text(bot, chat_id, buffer)
  end
rescue ErinosClient::Error => e
  LOGGER.error("Core error: #{e.message}")
  if message_id
    bot.api.edit_message_text(chat_id: chat_id, message_id: message_id, text: "Error: #{e.message}")
  else
    send_text(bot, chat_id, "Error: #{e.message}")
  end
rescue Telegram::Bot::Exceptions::ResponseError => e
  LOGGER.error("Telegram API error: #{e.message}")
end

LOGGER.info("Starting bot...")

Telegram::Bot::Client.run(TOKEN) do |bot|
  bot.listen do |message|
    next unless message.is_a?(Telegram::Bot::Types::Message) && message.text

    chat_id = message.chat.id

    case message.text
    when "/start", "/new"
      conversations.delete(chat_id)
      conv = client_for(message.from, clients).post("/conversations", {})
      conversations[chat_id] = conv["id"]
      send_text(bot, chat_id, "New conversation started.")
    when "/link"
      result = client_for(message.from, clients).post("/identity-links", {})
      send_text(bot, chat_id, "Link code: #{result['code']}\nEnter this from another channel within 5 minutes.")
    when %r{^/claim\s+(\S+)}
      code = $1
      begin
        client_for(message.from, clients).patch("/identity-links/#{code}", {})
        send_text(bot, chat_id, "Identity linked successfully.")
      rescue ErinosClient::Error => e
        send_text(bot, chat_id, "Error: #{e.message}")
      end
    when "/mailconfig"
      begin
        result = client_for(message.from, clients).get("/users/me/mail-config")
        send_text(bot, chat_id, "Email: #{result['email']}\nIMAP: #{result['imap_host']}:#{result['imap_port']}\nSMTP: #{result['smtp_host']}:#{result['smtp_port']}")
      rescue ErinosClient::Error => e
        send_text(bot, chat_id, e.message == "not configured" ? "No mail configured. Use the CLI to set it up:\nerin users mail-config me --email=... --smtp-host=... --imap-host=... --password=..." : "Error: #{e.message}")
      end
    else
      begin
        cl = client_for(message.from, clients)
        conversation_id = ensure_conversation(cl, conversations, chat_id)
        stream_response(bot, cl, chat_id, conversation_id, message.text)
      rescue ErinosClient::Error => e
        if e.message == "not found" && conversations.delete(chat_id)
          retry
        end
        LOGGER.error("Core error: #{e.message}")
        send_text(bot, chat_id, "Error: #{e.message}")
      rescue StandardError => e
        LOGGER.error("Unexpected error: #{e.class} — #{e.message}")
        send_text(bot, chat_id, "Something went wrong. Please try again.")
      end
    end
  end
end
