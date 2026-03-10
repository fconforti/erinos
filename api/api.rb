# frozen_string_literal: true

class Api < Sinatra::Base
  set :server, :puma
  set :host_authorization, permitted: :all

  CHATS = {}
  CHAT_MUTEX = Mutex.new

  # --- Auth ---

  def current_user
    id = request.env["HTTP_X_USER_ID"]
    halt 401, json(error: "unauthorized") unless id

    user = User.find_by(pin: id) || User.find_by(telegram_id: id)
    halt 401, json(error: "unauthorized") unless user
    user
  end

  def chat_for(user)
    CHAT_MUTEX.synchronize do
      CHATS[user.id] ||= Erin.chat(user: user, channel: "api")
    end
  end

  # --- Routes ---

  post "/api/chat" do
    user = current_user
    body = JSON.parse(request.body.read)
    message = body["message"]
    halt 400, json(error: "message required") unless message&.strip&.length&.positive?

    chat = chat_for(user)
    response = chat.ask(message)
    json(response: response.content)
  rescue RubyLLM::ContextLengthExceededError
    CHAT_MUTEX.synchronize { CHATS.delete(user.id) }
    status 400
    json(error: "context_length_exceeded")
  end

  post "/api/chat/stream" do
    user = current_user
    body = JSON.parse(request.body.read)
    message = body["message"]
    halt 400, json(error: "message required") unless message&.strip&.length&.positive?

    chat = chat_for(user)

    content_type "text/event-stream"
    headers "Cache-Control" => "no-cache"

    stream(:keep_open) do |out|
      chat.on_tool_call do |tool_call|
        label = tool_call.arguments["provider"] || tool_call.arguments["skill"] || tool_call.arguments["action"] || tool_call.name
        out << "event: tool_call\ndata: #{JSON.generate(name: tool_call.name, label: label)}\n\n"
      end

      chat.ask(message) do |chunk|
        next if chunk.content.nil? || chunk.content.empty?
        out << "event: token\ndata: #{JSON.generate(content: chunk.content)}\n\n"
      end

      out << "event: done\ndata: {}\n\n"
      out.close
    end
  rescue RubyLLM::ContextLengthExceededError
    CHAT_MUTEX.synchronize { CHATS.delete(user.id) }
    status 400
    json(error: "context_length_exceeded")
  end

  post "/api/auth/register" do
    body = JSON.parse(request.body.read)
    name = body["name"]&.strip
    pin = body["pin"]&.strip

    halt 400, json(error: "name and pin required") unless name&.length&.positive? && pin&.length&.positive?

    user = User.create!(name: name, pin: pin)
    json(user: { id: user.id, name: user.name })
  rescue ActiveRecord::RecordInvalid => e
    status 422
    json(error: e.message)
  end

  get "/api/auth/me" do
    user = current_user
    json(user: { id: user.id, name: user.name })
  end

  get "/health" do
    json(status: "ok")
  end

  private

  def json(data)
    content_type :json
    data.to_json
  end
end
