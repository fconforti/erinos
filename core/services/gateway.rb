# frozen_string_literal: true

class Gateway
  def initialize(user)
    @user = user
  end

  def create_conversation(agent_id: nil)
    agent = agent_id ? Agent.find(agent_id) : Agent.find_by!(default: true)
    @user.conversations.create!(agent: agent)
  end

  def reply(conversation, content, on_tool_call: nil, &on_chunk)
    ChatService.new(conversation).reply(content, on_tool_call: on_tool_call, &on_chunk)
  end
end
