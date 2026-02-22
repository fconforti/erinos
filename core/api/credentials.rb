# frozen_string_literal: true

require "net/http"
require "json"

class CredentialsAPI < BaseAPI
  SENSITIVE_KEYS = %w[password client_secret access_token refresh_token token_expires_at].freeze

  GOOGLE_DEVICE_AUTH_URL = "https://oauth2.googleapis.com/device/code"
  GOOGLE_TOKEN_URL = "https://oauth2.googleapis.com/token"
  GOOGLE_CALENDAR_SCOPE = "https://www.googleapis.com/auth/calendar"

  get "/users/:user_id/credentials" do
    user = find_user!
    user.user_credentials.map { |c| { kind: c.kind } }.to_json
  end

  get "/users/:user_id/credentials/:kind" do
    user = find_user!
    cred = user.user_credentials.find_by(kind: params[:kind])
    halt 404, { error: "not configured" }.to_json unless cred
    serialize(cred)
  end

  patch "/users/:user_id/credentials/:kind" do
    user = find_user!
    data = json_body
    cred = user.user_credentials.find_or_initialize_by(kind: params[:kind])
    cred.data = (cred.data || {}).merge(data.transform_keys(&:to_s))
    halt 422, { errors: cred.errors.full_messages }.to_json unless cred.save
    serialize(cred)
  end

  delete "/users/:user_id/credentials/:kind" do
    user = find_user!
    cred = user.user_credentials.find_by(kind: params[:kind])
    halt 404, { error: "not configured" }.to_json unless cred
    cred.destroy
    [204, ""]
  end

  post "/users/:user_id/credentials/google/authorize" do
    user = find_user!
    cred = user.user_credentials.find_by(kind: "google")
    halt 422, { error: "Google credential not configured. Set client_id and client_secret first." }.to_json unless cred
    data = cred.data
    halt 422, { error: "Missing client_id or client_secret." }.to_json unless data["client_id"] && data["client_secret"]

    uri = URI(GOOGLE_DEVICE_AUTH_URL)
    res = Net::HTTP.post_form(uri, {
      client_id: data["client_id"],
      scope: GOOGLE_CALENDAR_SCOPE
    })
    body = JSON.parse(res.body)

    halt 502, { error: "Google auth failed: #{body['error_description'] || body['error']}" }.to_json unless res.is_a?(Net::HTTPSuccess)

    cred.update!(data: data.merge("device_code" => body["device_code"]))

    {
      verification_url: body["verification_url"],
      user_code: body["user_code"],
      expires_in: body["expires_in"],
      interval: body["interval"]
    }.to_json
  end

  post "/users/:user_id/credentials/google/poll" do
    user = find_user!
    cred = user.user_credentials.find_by(kind: "google")
    halt 422, { error: "Google credential not configured." }.to_json unless cred
    data = cred.data
    halt 422, { error: "No pending authorization. Run authorize first." }.to_json unless data["device_code"]

    uri = URI(GOOGLE_TOKEN_URL)
    res = Net::HTTP.post_form(uri, {
      client_id: data["client_id"],
      client_secret: data["client_secret"],
      device_code: data["device_code"],
      grant_type: "urn:ietf:params:oauth:grant-type:device_code"
    })
    body = JSON.parse(res.body)

    if res.is_a?(Net::HTTPSuccess)
      cred.update!(data: data.merge(
        "access_token" => body["access_token"],
        "refresh_token" => body["refresh_token"],
        "token_expires_at" => (Time.now + body["expires_in"].to_i).iso8601
      ).tap { |d| d.delete("device_code") })
      { status: "authorized" }.to_json
    else
      { status: "pending", error: body["error"] }.to_json
    end
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

  def serialize(cred)
    safe_data = cred.data.reject { |k, _| SENSITIVE_KEYS.include?(k.to_s) }
    { kind: cred.kind, data: safe_data }.to_json
  end
end
