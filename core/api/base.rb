# frozen_string_literal: true

class BaseAPI < Sinatra::Base
  before { content_type :json }

  private

  def json_body
    body = request.body.read
    halt 400, { error: "bad request" }.to_json if body.empty?
    JSON.parse(body, symbolize_names: true)
  rescue JSON::ParserError
    halt 400, { error: "invalid JSON" }.to_json
  end
end
