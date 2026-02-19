# frozen_string_literal: true

require_relative "base"

module Commands
  class Models < Base
    namespace :models

    desc "list", "List all models"
    def list
      rows = client.get("/models")
      if rows.empty?
        say "No models found.", :yellow
        return
      end

      print_list(%w[ID Provider Name Created], rows.map { |m|
        [m["id"], m["provider"], m["name"], m["created_at"]]
      })
    end

    desc "show ID", "Show a model"
    def show(id)
      m = client.get("/models/#{id}")
      print_record(m)
    end

    desc "create", "Create a model"
    method_option :provider, required: true, type: :string
    method_option :name,     required: true, type: :string
    method_option :credentials, type: :hash, default: {}
    def create
      body = {
        provider: options[:provider],
        name: options[:name],
        credentials: options[:credentials]
      }
      m = client.post("/models", body)
      say "Created model #{m["id"]}.", :green
      print_record(m)
    end

    desc "update ID", "Update a model"
    method_option :provider,    type: :string
    method_option :name,        type: :string
    method_option :credentials, type: :hash
    def update(id)
      body = {}
      body[:provider]    = options[:provider]    if options[:provider]
      body[:name]        = options[:name]        if options[:name]
      body[:credentials] = options[:credentials] if options[:credentials]

      m = client.patch("/models/#{id}", body)
      say "Updated model #{m["id"]}.", :green
      print_record(m)
    end

    desc "delete ID", "Delete a model"
    def delete(id)
      client.delete("/models/#{id}")
      say "Deleted model #{id}.", :green
    end

    private

    def print_record(m)
      field "ID",          m["id"]
      field "Provider",    m["provider"]
      field "Name",        m["name"]
      field "Credentials", JSON.generate(m["credentials"]) if m["credentials"]
      field "Created",     m["created_at"]
      field "Updated",     m["updated_at"]
    end
  end
end
