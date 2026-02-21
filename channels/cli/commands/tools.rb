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

      groups = rows.group_by { |t| t["group"] || "general" }
      groups.each do |group, tools|
        say ""
        say set_color(group, :cyan, :bold)
        tools.each { |t| say "  #{set_color(t['name'], :green).ljust(30)} #{t['description']}" }
      end
    end
  end
end
