#!/usr/bin/env ruby
require "thor"
require "net/http"
require "json"
require "uri"

module Erinos
  class CLI < Thor
    class_option :host, default: "http://localhost:9292", desc: "API base URL"

    desc "tts TEXT", "Convert text to speech"
    def tts(text)
      uri = URI("#{options[:host]}/api/tts")
      http = Net::HTTP.new(uri.host, uri.port)

      request = Net::HTTP::Post.new(uri.path, "Content-Type" => "application/json")
      request.body = { text: text }.to_json

      response = http.request(request)
      result = JSON.parse(response.body)

      if response.code == "200"
        puts result["file"]
      else
        $stderr.puts "Error: #{result["error"]}"
        exit 1
      end
    end
  end
end

Erinos::CLI.start(ARGV)
