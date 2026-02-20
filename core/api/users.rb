# frozen_string_literal: true

class UsersAPI < BaseAPI
  get "/users/:id" do
    user = find_user!
    serialize(user)
  end

  patch "/users/:id" do
    user = find_user!
    data = json_body
    user.update!(data.slice(:email, :name, :timezone))
    serialize(user)
  end

  private

  def find_user!
    if params[:id] == "me"
      current_user
    else
      User.find(params[:id])
    end
  rescue ActiveRecord::RecordNotFound
    halt 404, { error: "not found" }.to_json
  end

  def serialize(user)
    { id: user.id, name: user.name, email: user.email, timezone: user.timezone }.to_json
  end
end
