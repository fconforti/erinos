# frozen_string_literal: true

require "thor"
require "readline"

module Commands
  class Chat < Base
    desc "start", "Start an interactive chat with Erin"
    option :agent_id, type: :numeric, desc: "Agent ID (defaults to the default agent)"
    def start
      body = options[:agent_id] ? { agent_id: options[:agent_id] } : {}
      conversation = client.post("/conversations", body)
      conversation_id = conversation["id"]

      say "Chat started (conversation #{conversation_id}). Type 'exit' to quit.\n\n"

      setup_completion

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

    COMMANDS = %w[exit quit].freeze

    def setup_completion
      Readline.completion_proc = ->(input) { COMMANDS.grep(/\A#{Regexp.escape(input)}/) }
      Readline.completion_append_character = " "
    end

    def prompt
      Readline.readline("\001\e[32m\002you>\001\e[0m\002 ", true)
    end

    def stream_reply(conversation_id, content)
      spinner = Spinner.new
      spinner.start("Thinking")
      first_chunk = true

      client.post_sse("/conversations/#{conversation_id}/messages", { content: content }) do |data|
        if data["done"]
          spinner.stop if first_chunk
          $stdout.write "\n\n"
        elsif data["tool_call"]
          label = data["tool_call"].tr("_", " ").capitalize
          spinner.update(label)
        elsif data["content"] && !data["content"].empty?
          if first_chunk
            spinner.stop
            $stdout.write "\e[36merin>\e[0m #{data["content"]}"
            first_chunk = false
          else
            $stdout.write data["content"]
          end
        elsif data["error"]
          spinner.stop
          warn "\e[31mError: #{data["error"]}\e[0m\n"
        end
      end
    end

    class Spinner
      FRAMES = %w[⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏].freeze

      def start(text)
        @text = text
        @running = true
        @thread = Thread.new do
          i = 0
          while @running
            $stdout.write "\r\e[K\e[33m#{FRAMES[i % FRAMES.size]}\e[0m #{@text}..."
            $stdout.flush
            i += 1
            sleep 0.08
          end
        end
      end

      def update(text)
        @text = text
      end

      def stop
        return unless @running

        @running = false
        @thread&.join
        $stdout.write "\r\e[K"
        $stdout.flush
      end
    end
  end
end
