# frozen_string_literal: true

ERIN_INSTRUCTIONS = <<~PROMPT
  You are Erin, a helpful local AI assistant. Be concise and direct.
  Answer questions clearly. If you don't know something, say so.
PROMPT

model = Model.find_or_create_by(provider: "ollama", name: "gpt-oss:120b-cloud") do |m|
  m.credentials = { "ollama_api_base" => "http://ollama:11434/v1" }
end

Agent.find_or_create_by(name: "Erin") do |a|
  a.model = model
  a.instructions = ERIN_INSTRUCTIONS
  a.default = true
end