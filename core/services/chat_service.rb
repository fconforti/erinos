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

  def reply(user_content, on_tool_call: nil, &on_chunk)
    @conversation.messages.create!(role: "user", content: user_content)

    chat = @context.chat(model: @model.name, provider: @model.provider.to_sym, assume_model_exists: true)
    chat.with_instructions(@agent.instructions)
    chat.on_tool_call { |tool_call| on_tool_call.call(tool_call) } if on_tool_call

    user = @conversation.user
    tool_context = { timezone: user.timezone, user: user }
    tool_names = user.user_tools.pluck(:tool)
    tool_names.each { |name| chat.with_tool(TOOL_CATALOG.fetch(name)[:klass].new(**tool_context)) }

    @conversation.messages.order(:created_at).each do |msg|
      chat.messages << RubyLLM::Message.new(role: msg.role.to_sym, content: msg.content)
    end

    response = chat.ask(user_content, &on_chunk)

    @conversation.messages.create!(role: "assistant", content: response.content)
  end
end
