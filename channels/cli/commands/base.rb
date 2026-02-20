# frozen_string_literal: true

require "thor"

module Commands
  class Base < Thor
    no_commands do
      def invoke_command(command, *args)
        super
      rescue ErinosClient::Error => e
        warn "\e[31mError: #{e.message}\e[0m"
        exit 1
      end
    end

    private

    def client
      @client ||= ErinosClient.new
    end

    def field(label, value)
      say "#{set_color(label.to_s.ljust(14), :cyan)}#{value}"
    end

    def print_list(headers, rows)
      table = [headers.map { |h| set_color(h, :bold) }]
      rows.each { |r| table << r }
      print_table(table)
    end
  end
end
