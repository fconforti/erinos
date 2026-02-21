# frozen_string_literal: true

class UserToolsAPI < BaseAPI
  get "/users/:user_id/tools" do
    user = find_user!
    user.user_tools.pluck(:tool).to_json
  end

  post "/users/:user_id/tools" do
    user = find_user!
    data = json_body
    user_tool = user.user_tools.new(tool: data[:tool])
    halt 422, { errors: user_tool.errors.full_messages }.to_json unless user_tool.save
    [201, { tool: user_tool.tool }.to_json]
  end

  delete "/users/:user_id/tools/:tool" do
    user = find_user!
    user_tool = user.user_tools.find_by(tool: params[:tool])
    halt 404, { error: "not found" }.to_json unless user_tool
    user_tool.destroy
    [204, ""]
  end

  private

  def find_user!
    if params[:user_id] == "me"
      current_user
    else
      User.find(params[:user_id])
    end
  rescue ActiveRecord::RecordNotFound
    halt 404, { error: "not found" }.to_json
  end
end
