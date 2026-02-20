# frozen_string_literal: true

class Gateway
  def create_conversation(agent_id: nil)
    agent = agent_id ? Agent.find(agent_id) : Agent.find_by!(default: true)
    Conversation.create!(agent: agent)
  end

  def reply(conversation, content, &on_chunk)
    ChatService.new(conversation).reply(content, &on_chunk)
  end
end
