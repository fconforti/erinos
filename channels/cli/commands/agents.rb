# frozen_string_literal: true

require_relative "base"

module Commands
  class Agents < Base
    namespace :agents

    desc "list", "List all agents"
    def list
      rows = client.get("/agents")
      if rows.empty?
        say "No agents found.", :yellow
        return
      end

      print_list(%w[ID Model Name Default Created], rows.map { |a|
        [a["id"], a["model_id"], a["name"], a["default"], a["created_at"]]
      })
    end

    desc "show ID", "Show an agent (includes tools)"
    def show(id)
      a = client.get("/agents/#{id}")
      print_record(a)
    end

    desc "default", "Show the default agent"
    def default
      a = client.get("/agents/default")
      print_record(a)
    end

    desc "create", "Create an agent"
    method_option :model_id,     required: true, type: :numeric, aliases: "-m"
    method_option :name,         required: true, type: :string,  aliases: "-n"
    method_option :instructions, required: true, type: :string,  aliases: "-i"
    method_option :default,      type: :boolean, default: false
    def create
      body = {
        model_id: options[:model_id],
        name: options[:name],
        instructions: options[:instructions],
        default: options[:default]
      }
      a = client.post("/agents", body)
      say "Created agent #{a["id"]}.", :green
      print_record(a)
    end

    desc "update ID", "Update an agent"
    method_option :model_id,     type: :numeric, aliases: "-m"
    method_option :name,         type: :string,  aliases: "-n"
    method_option :instructions, type: :string,  aliases: "-i"
    method_option :default,      type: :boolean
    def update(id)
      body = {}
      body[:model_id]     = options[:model_id]     if options.key?("model_id")
      body[:name]         = options[:name]         if options.key?("name")
      body[:instructions] = options[:instructions] if options.key?("instructions")
      body[:default]       = options[:default]      if options.key?("default")

      a = client.patch("/agents/#{id}", body)
      say "Updated agent #{a["id"]}.", :green
      print_record(a)
    end

    desc "delete ID", "Delete an agent"
    def delete(id)
      client.delete("/agents/#{id}")
      say "Deleted agent #{id}.", :green
    end

    # --- Agent-tool management ---

    desc "tools ID", "List tools assigned to an agent"
    def tools(id)
      rows = client.get("/agents/#{id}/tools")
      if rows.empty?
        say "No tools assigned.", :yellow
        return
      end

      print_list(%w[Tool], rows.map { |t| [t["tool"]] })
    end

    desc "assign-tool ID", "Assign a tool to an agent"
    method_option :tool, required: true, type: :string
    def assign_tool(id)
      client.post("/agents/#{id}/tools", { tool: options[:tool] })
      say "Assigned tool #{options[:tool]} to agent #{id}.", :green
    end

    desc "remove-tool ID", "Remove a tool from an agent"
    method_option :tool, required: true, type: :string
    def remove_tool(id)
      client.delete("/agents/#{id}/tools/#{options[:tool]}")
      say "Removed tool #{options[:tool]} from agent #{id}.", :green
    end

    private

    def print_record(a)
      field "ID",           a["id"]
      field "Model ID",     a["model_id"]
      field "Name",         a["name"]
      field "Instructions", a["instructions"]
      field "Default",      a["default"]
      field "Created",      a["created_at"]
      field "Updated",      a["updated_at"]
      if a["tools"] && !a["tools"].empty?
        field "Tools", a["tools"].map { |t| t["name"] }.join(", ")
      end
    end
  end
end
