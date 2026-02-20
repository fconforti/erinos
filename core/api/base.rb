# frozen_string_literal: true

class BaseAPI < Sinatra::Base
  before { content_type :json }

  private

  def current_user
    provider = request.env["HTTP_X_IDENTITY_PROVIDER"]
    uid = request.env["HTTP_X_IDENTITY_UID"]
    halt 401, { error: "unauthorized" }.to_json unless provider && uid

    identity = Identity.find_or_initialize_by(provider: provider, uid: uid)
    unless identity.persisted?
      name = request.env["HTTP_X_IDENTITY_NAME"]
      user = User.create!(name: name, role: User.count.zero? ? "admin" : "user")
      identity.user = user
      identity.save!
    end

    user = identity.user
    tz = request.env["HTTP_X_IDENTITY_TIMEZONE"]
    user.update!(timezone: tz) if tz && user.timezone != tz
    user
  end

  def json_body
    body = request.body.read
    halt 400, { error: "bad request" }.to_json if body.empty?
    JSON.parse(body, symbolize_names: true)
  rescue JSON::ParserError
    halt 400, { error: "invalid JSON" }.to_json
  end
end
