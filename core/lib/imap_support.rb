# frozen_string_literal: true

require "net/imap"

module ImapSupport
  private

  def connect_imap
    imap = Net::IMAP.new(@config["imap_host"], port: @config["imap_port"], ssl: @config["imap_port"] == 993)
    imap.login(@config["email"], @config["password"])
    imap
  end
end
