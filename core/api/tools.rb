# frozen_string_literal: true

class ToolsAPI < BaseAPI
  get "/tools/catalog" do
    TOOL_CATALOG.map { |name, entry| { name: name, group: entry[:group], description: entry[:klass].description } }.to_json
  end
end
