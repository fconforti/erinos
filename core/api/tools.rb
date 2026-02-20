# frozen_string_literal: true

class ToolsAPI < BaseAPI
  get "/tools/catalog" do
    TOOL_CATALOG.map { |name, klass| { name: name, description: klass.description } }.to_json
  end
end
