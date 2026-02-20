# frozen_string_literal: true

class MessagesAPI < BaseAPI
  get "/conversations/:conversation_id/messages" do
    conversation = find_conversation!
    conversation.messages.order(:created_at).map { |m| serialize(m) }.to_json
  end

  post "/conversations/:conversation_id/messages" do
    conversation = find_conversation!
    body = json_body
    halt 400, { error: "content is required" }.to_json unless body[:content]&.strip&.length&.positive?

    content_type "text/event-stream"
    stream(:keep_open) do |out|
      begin
        gateway = Gateway.new
        message = gateway.reply(conversation, body[:content]) do |chunk|
          out << "data: #{JSON.generate(content: chunk.content)}\n\n" if chunk.content
        end
        out << "data: #{JSON.generate(content: "", done: true, message: serialize(message))}\n\n"
      rescue => e
        out << "event: error\ndata: #{JSON.generate(error: e.message)}\n\n"
      ensure
        out.close
      end
    end
  end

  private

  def find_conversation!
    Conversation.find(params[:conversation_id])
  rescue ActiveRecord::RecordNotFound
    halt 404, { error: "not found" }.to_json
  end

  def serialize(message)
    { id: message.id, role: message.role, content: message.content,
      created_at: message.created_at }
  end
end
