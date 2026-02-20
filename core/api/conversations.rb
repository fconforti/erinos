# frozen_string_literal: true

class ConversationsAPI < BaseAPI
  post "/conversations" do
    conversation = Gateway.new.create_conversation(agent_id: json_body[:agent_id])
    [201, serialize(conversation).to_json]
  rescue ActiveRecord::RecordNotFound
    halt 404, { error: "agent not found" }.to_json
  end

  get "/conversations/:id" do
    conversation = find_conversation!
    serialize(conversation).merge(
      messages: conversation.messages.order(:created_at).map { |m| serialize_message(m) }
    ).to_json
  end

  delete "/conversations/:id" do
    find_conversation!.destroy
    [204, ""]
  end

  private

  def find_conversation!
    Conversation.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    halt 404, { error: "not found" }.to_json
  end

  def serialize(conversation)
    { id: conversation.id, agent_id: conversation.agent_id,
      created_at: conversation.created_at, updated_at: conversation.updated_at }
  end

  def serialize_message(message)
    { id: message.id, role: message.role, content: message.content,
      created_at: message.created_at }
  end
end
