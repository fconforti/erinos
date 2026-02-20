# frozen_string_literal: true

require "faraday"
require "json"
require "net/http"
require "uri"

class ErinosClient
  class Error < StandardError; end

  def initialize(url: ENV.fetch("CORE_URL", "http://core:4567"), headers: {})
    @headers = headers
    @conn = Faraday.new(url: url) do |f|
      f.request :json
      f.headers.merge!(headers)
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

  def post_sse(path, body, &on_event)
    url = "#{@conn.url_prefix}#{path}"
    uri = URI(url)

    Net::HTTP.start(uri.host, uri.port) do |http|
      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request["Accept"] = "text/event-stream"
      @headers.each { |k, v| request[k] = v }
      request.body = JSON.generate(body)

      http.request(request) do |response|
        unless response.code.start_with?("2")
          body = parse_json(response.body)
          msg = body.is_a?(Hash) && body["error"] || "request failed (#{response.code})"
          raise Error, msg
        end

        buffer = +""
        response.read_body do |chunk|
          buffer << chunk
          while (idx = buffer.index("\n\n"))
            frame = buffer.slice!(0, idx + 2)
            frame.each_line do |line|
              if line.start_with?("data: ")
                data = parse_json(line.sub("data: ", "").strip)
                on_event.call(data) if data
              end
            end
          end
        end
      end
    end
  rescue Errno::ECONNREFUSED, SocketError
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

    raise Error, msg
  end

  def connection_error
    raise Error, "cannot reach core at #{@conn.url_prefix}"
  end

  def parse_json(raw)
    return nil if raw.to_s.empty?

    JSON.parse(raw)
  rescue JSON::ParserError
    raise Error, "unexpected response from core — #{raw[0, 120]}"
  end
end
