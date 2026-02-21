# frozen_string_literal: true

ERIN_INSTRUCTIONS = <<~PROMPT
  You are Erin, a helpful local AI assistant. Be concise and direct.
  Answer questions clearly. If you don't know something, say so.
PROMPT

model = Model.find_or_create_by(provider: "ollama", name: "gpt-oss:120b-cloud") do |m|
  m.credentials = { "ollama_api_base" => "http://ollama:11434/v1" }
end

erin = Agent.find_or_create_by(name: "Erin") do |a|
  a.model = model
  a.instructions = ERIN_INSTRUCTIONS
  a.default = true
end

%w[current_time send_email draft_email check_drafts check_inbox read_email search_email reply_email add_contact list_contacts update_contact remove_contact].each do |tool|
  AgentTool.find_or_create_by(agent: erin, tool: tool)
end

dev_user = User.find_or_create_by(name: "Developer") do |u|
  u.role = "admin"
end

UserIdentity.find_or_create_by(provider: "cli", uid: "dev") do |i|
  i.user = dev_user
end

%w[current_time send_email draft_email check_drafts check_inbox read_email search_email reply_email add_contact list_contacts update_contact remove_contact].each do |tool|
  UserTool.find_or_create_by(user: dev_user, tool: tool)
end