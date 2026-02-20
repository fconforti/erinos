# frozen_string_literal: true

class AgentToolsAPI < BaseAPI
  get "/agents/:agent_id/tools" do
    agent = find_agent!
    agent.agent_tools.map { |at| { tool: at.tool } }.to_json
  end

  post "/agents/:agent_id/tools" do
    agent = find_agent!
    agent_tool = agent.agent_tools.new(tool: json_body[:tool])
    halt 422, { errors: agent_tool.errors.full_messages }.to_json unless agent_tool.save
    [201, { agent_id: agent.id, tool: agent_tool.tool }.to_json]
  end

  delete "/agents/:agent_id/tools/:tool" do
    agent = find_agent!
    agent_tool = agent.agent_tools.find_by(tool: params[:tool])
    halt 404, { error: "not found" }.to_json unless agent_tool
    agent_tool.destroy
    [204, ""]
  end

  private

  def find_agent!
    Agent.find(params[:agent_id])
  rescue ActiveRecord::RecordNotFound
    halt 404, { error: "not found" }.to_json
  end
end
