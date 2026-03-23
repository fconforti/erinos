#!/usr/bin/env ruby
require "thor"
require "net/http"
require "json"
require "uri"

module Erinos
  class CLI < Thor
    class_option :host, default: "http://localhost:9292", desc: "API base URL"

    desc "tts [TEXT]", "Convert text to speech (Chatterbox Turbo)"
    option :file, aliases: "-f", desc: "Read text from file"
    option :temperature, aliases: "-t", type: :numeric, desc: "Temperature (default: 0.8)"
    def tts(text = nil)
      if options[:file]
        text = File.read(options[:file])
      end

      if text.nil? || text.strip.empty?
        $stderr.puts "Provide text as argument or use --file/-f"
        exit 1
      end

      params = { text: text }
      params[:temperature] = options[:temperature] if options[:temperature]

      run_tts_job("/api/tts", params)
    end

    desc "tts:retry JOB_ID", "Re-generate specific chunks from a TTS job"
    option :chunks, aliases: "-c", required: true, desc: "Chunk numbers to retry (e.g. 2,4)"
    option :temperature, aliases: "-t", type: :numeric, desc: "Temperature (default: 0.8)"
    def tts__retry(job_id)
      chunks = options[:chunks].split(",").map(&:to_i)
      params = { chunks: chunks }
      params[:temperature] = options[:temperature] if options[:temperature]

      result = api_post("/api/tts/jobs/#{job_id}/retry", params)
      puts "Retrying chunks #{chunks.join(", ")} for job #{result["job_id"]}..."

      poll_job(result["job_id"])
    end

    private

    def run_tts_job(endpoint, params)
      result = api_post(endpoint, params)
      job_id = result["job_id"]
      puts "Job #{job_id} queued..."
      poll_job(job_id)
    end

    def poll_job(job_id)
      loop do
        job = api_get("/api/jobs/#{job_id}")

        case job["status"]
        when "done"
          puts "\n#{job["result"]["file"]}"
          break
        when "failed"
          $stderr.puts "\nError: #{job["error"]}"
          exit 1
        when "queued"
          print "\rStarting..."
          sleep 2
        else
          print "\rProcessing: #{job["progress"]}/#{job["total"]} chunks"
          sleep 2
        end
      end
    end

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
