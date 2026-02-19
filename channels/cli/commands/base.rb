# frozen_string_literal: true

require "thor"

module Commands
  class Base < Thor
    private

    def client
      @client ||= CoreClient.new
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
