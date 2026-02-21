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

    desc "list", "List all users"
    def list
      rows = client.get("/users")
      if rows.empty?
        say "No users found.", :yellow
        return
      end

      print_list(%w[ID Name Email Timezone], rows.map { |u|
        [u["id"], u["name"], u["email"] || "", u["timezone"]]
      })
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

    desc "mail-config ID", "Show or set mail config (use 'me' for yourself)"
    method_option :email, type: :string, desc: "Email address"
    method_option :imap_host, type: :string, desc: "IMAP host (e.g. imap.gmail.com)"
    method_option :imap_port, type: :numeric, desc: "IMAP port (default 993)"
    method_option :smtp_host, type: :string, desc: "SMTP host (e.g. smtp.gmail.com)"
    method_option :smtp_port, type: :numeric, desc: "SMTP port (default 587)"
    method_option :password, type: :string, desc: "Mail password or app password"
    def mail_config(id)
      body = {}
      %i[email imap_host imap_port smtp_host smtp_port password].each do |key|
        body[key] = options[key] if options[key]
      end

      if body.any?
        result = client.patch("/users/#{id}/mail-config", body)
      else
        result = client.get("/users/#{id}/mail-config")
      end

      field "Email", result["email"]
      field "IMAP", "#{result['imap_host']}:#{result['imap_port']}"
      field "SMTP", "#{result['smtp_host']}:#{result['smtp_port']}"
    end

    desc "contacts ID", "List contacts for a user (use 'me' for yourself)"
    def contacts(id)
      rows = client.get("/users/#{id}/contacts")
      if rows.empty?
        say "No contacts found.", :yellow
        return
      end

      print_list(%w[ID Name Email Phone], rows.map { |c|
        [c["id"], "#{c['first_name']} #{c['last_name']}", c["email"], c["phone"] || ""]
      })
    end

    desc "add-contact ID", "Add a contact for a user (use 'me' for yourself)"
    method_option :first_name, type: :string, required: true, desc: "First name"
    method_option :last_name, type: :string, required: true, desc: "Last name"
    method_option :email, type: :string, required: true, desc: "Email address"
    method_option :phone, type: :string, desc: "Phone number"
    def add_contact(id)
      body = {
        first_name: options[:first_name],
        last_name: options[:last_name],
        email: options[:email]
      }
      body[:phone] = options[:phone] if options[:phone]

      result = client.post("/users/#{id}/contacts", body)
      say "Contact added: #{set_color("#{result['first_name']} #{result['last_name']}", :green)} <#{result['email']}>"
    end

    desc "update-contact ID CONTACT_ID", "Update a contact for a user"
    method_option :first_name, type: :string, desc: "First name"
    method_option :last_name, type: :string, desc: "Last name"
    method_option :email, type: :string, desc: "Email address"
    method_option :phone, type: :string, desc: "Phone number"
    def update_contact(id, contact_id)
      body = {}
      body[:first_name] = options[:first_name] if options[:first_name]
      body[:last_name] = options[:last_name] if options[:last_name]
      body[:email] = options[:email] if options[:email]
      body[:phone] = options[:phone] if options[:phone]

      if body.empty?
        say "Nothing to update. Use --first-name, --last-name, --email, or --phone.", :yellow
        return
      end

      result = client.patch("/users/#{id}/contacts/#{contact_id}", body)
      say "Contact updated: #{set_color("#{result['first_name']} #{result['last_name']}", :green)} <#{result['email']}>"
    end

    desc "remove-contact ID CONTACT_ID", "Remove a contact for a user"
    def remove_contact(id, contact_id)
      client.delete("/users/#{id}/contacts/#{contact_id}")
      say set_color("Contact removed.", :yellow)
    end

    desc "tools ID", "List tools enabled for a user (use 'me' for yourself)"
    def tools(id)
      tools = client.get("/users/#{id}/tools")
      if tools.empty?
        say "No custom tools set (using agent defaults).", :yellow
      else
        tools.each { |t| say "  #{t}" }
      end
    end

    desc "enable-tool ID TOOL", "Enable a tool for a user"
    def enable_tool(id, tool)
      client.post("/users/#{id}/tools", { tool: tool })
      say "#{set_color(tool, :green)} enabled."
    end

    desc "disable-tool ID TOOL", "Disable a tool for a user"
    def disable_tool(id, tool)
      client.delete("/users/#{id}/tools/#{tool}")
      say "#{set_color(tool, :yellow)} disabled."
    end
  end
end
