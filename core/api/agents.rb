# frozen_string_literal: true

class AgentsAPI < BaseAPI
  get "/agents" do
    Agent.all.map { |a| serialize(a) }.to_json
  end

  get "/agents/default" do
    agent = Agent.find_by(default: true)
    halt 404, { error: "no default agent" }.to_json unless agent
    serialize(agent).merge(tools: serialize_tools(agent)).to_json
  end

  get "/agents/:id" do
    agent = find_agent!
    serialize(agent).merge(tools: serialize_tools(agent)).to_json
  end

  post "/agents" do
    agent = Agent.new(json_body.slice(:model_id, :name, :instructions, :default))
    halt 422, { errors: agent.errors.full_messages }.to_json unless agent.save
    [201, serialize(agent).to_json]
  end

  patch "/agents/:id" do
    agent = find_agent!
    halt 422, { errors: agent.errors.full_messages }.to_json unless agent.update(json_body.slice(:model_id, :name, :instructions, :default))
    serialize(agent).to_json
  end

  delete "/agents/:id" do
    find_agent!.destroy
    [204, ""]
  end

  private

  def find_agent!
    Agent.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    halt 404, { error: "not found" }.to_json
  end

  def serialize(agent)
    { id: agent.id, model_id: agent.model_id, name: agent.name,
      instructions: agent.instructions, default: agent.default,
      created_at: agent.created_at, updated_at: agent.updated_at }
  end

  def serialize_tools(agent)
    agent.tools.map { |t| { id: t.id, name: t.name } }
  end
end
