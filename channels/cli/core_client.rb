# frozen_string_literal: true

require "faraday"
require "json"

class CoreClient
  def initialize
    @conn = Faraday.new(url: ENV.fetch("CORE_URL", "http://core:4567")) do |f|
      f.request :json
      f.adapter Faraday.default_adapter
    end
  end

  def get(path)
    handle(@conn.get(path))
  rescue Faraday::ConnectionFailed
    connection_error
  end

  def post(path, body)
    handle(@conn.post(path, body))
  rescue Faraday::ConnectionFailed
    connection_error
  end

  def patch(path, body)
    handle(@conn.patch(path, body))
  rescue Faraday::ConnectionFailed
    connection_error
  end

  def delete(path)
    resp = @conn.delete(path)
    return nil if resp.status == 204

    handle(resp)
  rescue Faraday::ConnectionFailed
    connection_error
  end

  private

  def handle(resp)
    body = parse_json(resp.body)

    return body if resp.status.between?(200, 299)

    msg = if body.is_a?(Hash) && body["errors"]
            body["errors"].join(", ")
          elsif body.is_a?(Hash) && body["error"]
            body["error"]
          else
            "request failed (#{resp.status})"
          end

    warn "\e[31mError: #{msg}\e[0m"
    exit 1
  end

  def connection_error
    warn "\e[31mError: cannot reach core at #{@conn.url_prefix}\e[0m"
    exit 1
  end

  def parse_json(raw)
    return nil if raw.to_s.empty?

    JSON.parse(raw)
  rescue JSON::ParserError
    warn "\e[31mError: unexpected response from core — #{raw[0, 120]}\e[0m"
    exit 1
  end
end
