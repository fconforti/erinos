# frozen_string_literal: true

class ChatService
  def initialize(conversation)
    @conversation = conversation
    @agent = conversation.agent
    @model = @agent.model

    @context = RubyLLM.context do |config|
      config.ollama_api_base = @model.credentials["ollama_api_base"]
    end
  end

  def reply(user_content, &on_chunk)
    @conversation.messages.create!(role: "user", content: user_content)

    chat = @context.chat(model: @model.name, provider: @model.provider.to_sym, assume_model_exists: true)
    chat.with_instructions(@agent.instructions)

    user = @conversation.user
    mail_config = user.mail_config&.attributes&.slice("email", "imap_host", "imap_port", "smtp_host", "smtp_port", "password")
    tool_context = { timezone: user.timezone, mail_config: mail_config }
    @agent.agent_tools.pluck(:tool).each { |name| chat.with_tool(TOOL_CATALOG.fetch(name).new(**tool_context)) }

    @conversation.messages.order(:created_at).each do |msg|
      chat.messages << RubyLLM::Message.new(role: msg.role.to_sym, content: msg.content)
    end

    response = chat.ask(user_content, &on_chunk)

    @conversation.messages.create!(role: "assistant", content: response.content)
  end
end
