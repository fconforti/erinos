# frozen_string_literal: true

class ToolsAPI < BaseAPI
  get "/tools" do
    Tool.all.map { |t| serialize(t) }.to_json
  end

  get "/tools/:id" do
    serialize(find_tool!).to_json
  end

  post "/tools" do
    tool = Tool.new(json_body.slice(:name))
    halt 422, { errors: tool.errors.full_messages }.to_json unless tool.save
    [201, serialize(tool).to_json]
  end

  patch "/tools/:id" do
    tool = find_tool!
    halt 422, { errors: tool.errors.full_messages }.to_json unless tool.update(json_body.slice(:name))
    serialize(tool).to_json
  end

  delete "/tools/:id" do
    find_tool!.destroy
    [204, ""]
  end

  private

  def find_tool!
    Tool.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    halt 404, { error: "not found" }.to_json
  end

  def serialize(tool)
    { id: tool.id, name: tool.name,
      created_at: tool.created_at, updated_at: tool.updated_at }
  end
end
