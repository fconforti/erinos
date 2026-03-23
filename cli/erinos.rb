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
      # Submit the job
      result = api_post("/api/tts", { text: text })
      job_id = result["job_id"]
      puts "Job #{job_id} queued..."

      # Poll until done
      loop do
        job = api_get("/api/jobs/#{job_id}")

        case job["status"]
        when "done"
          puts job["result"]["file"]
          break
        when "failed"
          $stderr.puts "Error: #{job["error"]}"
          exit 1
        else
          print "\rProcessing: #{job["progress"]}/#{job["total"]} chunks"
          sleep 2
        end
      end
    end

    private

    def api_get(path)
      uri = URI("#{options[:host]}#{path}")
      response = Net::HTTP.get_response(uri)
      JSON.parse(response.body)
    end

    def api_post(path, body)
      uri = URI("#{options[:host]}#{path}")
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Post.new(uri.path, "Content-Type" => "application/json")
      request.body = body.to_json
      response = http.request(request)
      result = JSON.parse(response.body)

      unless %w[200 201 202].include?(response.code)
        $stderr.puts "Error: #{result["error"]}"
        exit 1
      end

      result
    end
  end
end

Erinos::CLI.start(ARGV)
