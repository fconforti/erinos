# frozen_string_literal: true

class ChatService
  def initialize(conversation)
    @conversation = conversation
  end

  def reply(user_content, &on_chunk)
    @conversation.messages.create!(role: "user", content: user_content)

    chat = build_chat
    @conversation.messages.order(:created_at).each do |msg|
      chat.add_message(RubyLLM::Message.new(role: msg.role.to_sym, content: msg.content))
    end

    response = chat.ask(user_content, &on_chunk)
    @conversation.messages.create!(role: "assistant", content: response.content)
  end

  private

  def build_chat
    if @conversation.agent_id
      agent = @conversation.agent
      model = agent.model
      context = RubyLLM.context { |c| c.ollama_api_base = model.credentials["ollama_api_base"] }
      chat = context.chat(model: model.name, provider: model.provider.to_sym, assume_model_exists: true)
      chat.with_instructions(agent.instructions)
      chat
    else
      Erin.new
    end
  end
end
