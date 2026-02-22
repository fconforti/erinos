# frozen_string_literal: true

require "net/imap"

module EmailSupport
  def initialize(user: nil, **)
    @user = user
    @config = @user&.credential("mail")&.data
  end

  private

  def require_config!
    "Error: mail not configured. Ask the user to set up mail first." unless @config
  end

  def connect_imap
    imap = Net::IMAP.new(@config["imap_host"], port: @config["imap_port"], ssl: @config["imap_port"] == 993)
    imap.login(@config["email"], @config["password"])
    imap
  end

  def find_drafts_folder(imap)
    drafts = imap.list("", "*")&.find { |m| m.attr.include?(:Drafts) }
    drafts&.name || "[Gmail]/Drafts"
  end

  def smtp_settings
    {
      address: @config["smtp_host"],
      port: @config["smtp_port"],
      user_name: @config["email"],
      password: @config["password"],
      authentication: :plain,
      enable_starttls_auto: true
    }
  end

  def require_contact!(email)
    return unless @user
    return if @user.user_contacts.exists?(email: email)

    "Error: #{email} is not in the user's contacts. Ask the user to add them as a contact first."
  end
end
