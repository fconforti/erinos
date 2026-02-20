# frozen_string_literal: true

require_relative "base"

module Commands
  class Users < Base
    namespace :users

    desc "link", "Generate a code to link another channel to your account"
    def link
      result = client.post("/identity-links", {})
      say "Link code: #{set_color(result['code'], :green, :bold)}"
      say "Enter this code from another channel within 5 minutes."
    end

    desc "claim CODE", "Link your identity to an existing account using a code"
    def claim(code)
      client.patch("/identity-links/#{code}", {})
      say set_color("Identity linked successfully.", :green)
    end

    desc "show ID", "Show a user profile (use 'me' for yourself)"
    def show(id)
      result = client.get("/users/#{id}")
      field "Name", result["name"]
      field "Email", result["email"] || "(not set)"
      field "Timezone", result["timezone"]
    end

    desc "update ID", "Update a user profile (use 'me' for yourself)"
    method_option :email, type: :string, desc: "Email address"
    method_option :name, type: :string, desc: "Display name"
    method_option :timezone, type: :string, desc: "Timezone (e.g. Europe/Rome)"
    def update(id)
      body = {}
      body[:email] = options[:email] if options[:email]
      body[:name] = options[:name] if options[:name]
      body[:timezone] = options[:timezone] if options[:timezone]

      if body.empty?
        say "Nothing to update. Use --email, --name, or --timezone.", :yellow
        return
      end

      result = client.patch("/users/#{id}", body)
      field "Name", result["name"]
      field "Email", result["email"] || "(not set)"
      field "Timezone", result["timezone"]
    end
  end
end
