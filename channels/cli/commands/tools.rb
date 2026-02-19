# frozen_string_literal: true

require_relative "base"

module Commands
  class Tools < Base
    namespace :tools

    desc "list", "List all tools"
    def list
      rows = client.get("/tools")
      if rows.empty?
        say "No tools found.", :yellow
        return
      end

      print_list(%w[ID Name Created], rows.map { |t|
        [t["id"], t["name"], t["created_at"]]
      })
    end

    desc "show ID", "Show a tool"
    def show(id)
      t = client.get("/tools/#{id}")
      print_record(t)
    end

    desc "create", "Create a tool"
    method_option :name, required: true, type: :string
    def create
      t = client.post("/tools", { name: options[:name] })
      say "Created tool #{t["id"]}.", :green
      print_record(t)
    end

    desc "update ID", "Update a tool"
    method_option :name, required: true, type: :string
    def update(id)
      t = client.patch("/tools/#{id}", { name: options[:name] })
      say "Updated tool #{t["id"]}.", :green
      print_record(t)
    end

    desc "delete ID", "Delete a tool"
    def delete(id)
      client.delete("/tools/#{id}")
      say "Deleted tool #{id}.", :green
    end

    private

    def print_record(t)
      field "ID",      t["id"]
      field "Name",    t["name"]
      field "Created", t["created_at"]
      field "Updated", t["updated_at"]
    end
  end
end
