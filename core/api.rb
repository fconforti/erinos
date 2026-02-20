# frozen_string_literal: true

require_relative "config/application"
require "sinatra/base"

require_relative "api/base"
require_relative "api/models"
require_relative "api/agents"
require_relative "api/tools"
require_relative "api/agent_tools"
require_relative "api/conversations"
require_relative "api/messages"
require_relative "api/identity_links"

class API < Sinatra::Base
  set :bind, "0.0.0.0"

  before { content_type :json }

  use IdentityLinksAPI
  use MessagesAPI
  use ConversationsAPI
  use AgentToolsAPI
  use AgentsAPI
  use ModelsAPI
  use ToolsAPI

  get "/health" do
    { status: "ok" }.to_json
  end

  run! if app_file == $PROGRAM_NAME
end
