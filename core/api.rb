# frozen_string_literal: true

require_relative "config/application"
require "sinatra/base"

require_relative "api/base"
require_relative "api/models"
require_relative "api/agents"
require_relative "api/tools"
require_relative "api/agent_tools"

class API < Sinatra::Base
  set :bind, "0.0.0.0"

  before { content_type :json }

  use AgentToolsAPI
  use AgentsAPI
  use ModelsAPI
  use ToolsAPI

  get "/health" do
    { status: "ok" }.to_json
  end

  run! if app_file == $PROGRAM_NAME
end
