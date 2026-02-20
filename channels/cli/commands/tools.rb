# frozen_string_literal: true

require_relative "base"

module Commands
  class Tools < Base
    namespace :tools

    desc "catalog", "Show available tools from the catalog"
    def catalog
      rows = client.get("/tools/catalog")
      if rows.empty?
        say "No tools in catalog.", :yellow
        return
      end

      print_list(%w[Name Description], rows.map { |t|
        [t["name"], t["description"]]
      })
    end
  end
end
