# frozen_string_literal: true

require "faye/websocket"
require "eventmachine"
require "json"
require "net/http"
require "uri"
require "base64"
require "securerandom"

# Connects to the relay via WebSocket and forwards requests to the local API.
class TunnelClient
  def initialize(relay_url:, key:, api_url: "http://localhost:4567")
    @relay_url = relay_url
    @key = key
    @api_url = api_url
  end

  def run
    EM.run do
      connect
    end
  end

  private

  def connect
    url = "#{@relay_url}/tunnel"
    puts "[tunnel] Connecting to #{url}..."

    ws = Faye::WebSocket::Client.new(url, nil, headers: {
      "Authorization" => "Bearer #{@key}"
    })

    ws.on :open do |_|
      puts "[tunnel] Connected to relay"
    end

    ws.on :message do |event|
      Thread.new { handle_request(ws, event.data) }
    end

    ws.on :close do |event|
      puts "[tunnel] Disconnected (#{event.code}). Reconnecting in 5s..."
      EM.add_timer(5) { connect }
    end
  end

  def handle_request(ws, data)
    msg = JSON.parse(data)
    id = msg["id"]

    # Forward to local API
    uri = URI("#{@api_url}#{msg['path']}")
    http = Net::HTTP.new(uri.hostname, uri.port)
    http.read_timeout = 120

    req = Net::HTTP::Post.new(uri)
    (msg["headers"] || {}).each { |k, v| req[k] = v }

    if msg["file"]
      # Rebuild multipart request for audio
      boundary = SecureRandom.hex
      file_data = Base64.strict_decode64(msg["file"]["data"])
      body = "--#{boundary}\r\n" \
             "Content-Disposition: form-data; name=\"file\"; filename=\"#{msg['file']['filename']}\"\r\n" \
             "Content-Type: #{msg['file']['type']}\r\n\r\n" \
             "#{file_data}\r\n" \
             "--#{boundary}--\r\n"
      req["Content-Type"] = "multipart/form-data; boundary=#{boundary}"
      req.body = body
    else
      req.body = msg["body"]
    end

    response = http.request(req)

    # Send response back through tunnel
    reply = { id: id, status: response.code.to_i, headers: { "Content-Type" => response["Content-Type"] } }

    if response["Content-Type"]&.include?("audio/")
      reply[:body_base64] = Base64.strict_encode64(response.body)
    else
      reply[:body] = response.body
    end

    ws.send(JSON.generate(reply))
  rescue => e
    puts "[tunnel] Error handling request #{id}: #{e.message}"
    reply = { id: id, status: 500, body: { error: e.message }.to_json,
              headers: { "Content-Type" => "application/json" } }
    ws.send(JSON.generate(reply))
  end
end
