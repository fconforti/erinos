class TelegramBot
  def initialize(token: ENV.fetch("TELEGRAM_BOT_TOKEN"))
    @token = token
    @pending_links = {}
  end

  def run
    ::Telegram::Bot::Client.run(@token) do |bot|
      bot.listen do |message|
        next unless message.is_a?(::Telegram::Bot::Types::Message) && message.text

        handle(bot, message)
      end
    end
  end

  private

  def handle(bot, message)
    telegram_id = message.from.id
    user = User.find_by(telegram_id: telegram_id)

    if user
      respond(bot, message, user)
    elsif @pending_links[telegram_id]
      link_account(bot, message, telegram_id)
    else
      request_pin(bot, message, telegram_id)
    end
  end

  def request_pin(bot, message, telegram_id)
    @pending_links[telegram_id] = true
    bot.api.send_message(
      chat_id: message.chat.id,
      text: "I don't recognize you yet. Send me your PIN to link your account."
    )
  end

  def link_account(bot, message, telegram_id)
    pin = message.text.strip
    user = User.find_by(pin: pin)

    if user
      user.update!(telegram_id: telegram_id)
      @pending_links.delete(telegram_id)
      bot.api.send_message(
        chat_id: message.chat.id,
        text: "Welcome, #{user.name}!"
      )
    else
      bot.api.send_message(
        chat_id: message.chat.id,
        text: "Unknown PIN. Try again."
      )
    end
  end

  def respond(bot, message, user)
    client = ErinosClient.new(user_id: user.telegram_id)
    response = client.chat(message.text)

    bot.api.send_message(
      chat_id: message.chat.id,
      text: response["response"]
    )
  rescue ErinosClient::Error => e
    bot.api.send_message(
      chat_id: message.chat.id,
      text: e.message == "context_length_exceeded" ?
        "Our conversation got too long, so I've started a fresh one. Please try again." :
        "Something went wrong."
    )
  end
end
