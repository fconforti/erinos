# frozen_string_literal: true

require "thor"
require "io/console"

module Commands
  class Chat < Base
    desc "start", "Start an interactive chat with Erin"
    option :agent_id, type: :numeric, desc: "Agent ID (defaults to the default agent)"
    def start
      body = options[:agent_id] ? { agent_id: options[:agent_id] } : {}
      conversation = client.post("/conversations", body)
      conversation_id = conversation["id"]

      say "Chat started (conversation #{conversation_id}). Type 'exit' to quit.\n\n"

      loop do
        input = prompt
        break if input.nil?

        trimmed = input.strip
        next if trimmed.empty?
        break if %w[exit quit].include?(trimmed.downcase)

        stream_reply(conversation_id, trimmed)
      end

      say "\nBye!"
    end

    default_task :start

    private

    def prompt
      $stdout.write "\e[32myou>\e[0m "
      $stdout.flush
      $stdin.gets&.chomp
    end

    def stream_reply(conversation_id, content)
      $stdout.write "\e[36merin>\e[0m "

      client.post_sse("/conversations/#{conversation_id}/messages", { content: content }) do |data|
        if data["done"]
          $stdout.write "\n\n"
        elsif data["content"]
          $stdout.write data["content"]
        elsif data["error"]
          warn "\n\e[31mError: #{data["error"]}\e[0m\n"
        end
      end
    end
  end
end
