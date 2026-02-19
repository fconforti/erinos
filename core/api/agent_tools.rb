# frozen_string_literal: true

class AgentToolsAPI < BaseAPI
  get "/agents/:agent_id/tools" do
    agent = find_agent!
    agent.tools.map { |t| { id: t.id, name: t.name } }.to_json
  end

  post "/agents/:agent_id/tools" do
    agent = find_agent!
    tool = Tool.find(json_body[:tool_id])
    agent_tool = AgentTool.new(agent: agent, tool: tool)
    halt 422, { errors: agent_tool.errors.full_messages }.to_json unless agent_tool.save
    [201, { agent_id: agent.id, tool_id: tool.id }.to_json]
  rescue ActiveRecord::RecordNotFound
    halt 404, { error: "not found" }.to_json
  end

  delete "/agents/:agent_id/tools/:tool_id" do
    agent = find_agent!
    agent_tool = agent.agent_tools.find_by(tool_id: params[:tool_id])
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
