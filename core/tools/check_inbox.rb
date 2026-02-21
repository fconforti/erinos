# frozen_string_literal: true

require "net/imap"

class CheckInbox < RubyLLM::Tool
  description "Lists recent emails from the user's inbox. Returns subject, sender, date, and UID for each message."

  param :limit, desc: "Number of emails to fetch (default 10, max 50)", required: false

  def initialize(mail_config: nil, **)
    @config = mail_config
  end

  def execute(limit: "10")
    return "Error: mail not configured. Ask the user to set up mail first." unless @config

    count = [[limit.to_i, 1].max, 50].min
    imap = connect

    imap.select("INBOX")

    uids = imap.uid_search(["ALL"])
    return "Inbox is empty." if uids.empty?

    uids = uids.last(count)
    messages = imap.uid_fetch(uids, ["UID", "ENVELOPE", "FLAGS"])

    messages.reverse.map { |msg|
      env = msg.attr["ENVELOPE"]
      from = env.from&.first
      sender = from ? "#{from.name || ''} <#{from.mailbox}@#{from.host}>" : "unknown"
      flags = msg.attr["FLAGS"].map(&:to_s).join(", ")

      "UID: #{msg.attr['UID']} | From: #{sender} | Subject: #{env.subject} | Date: #{env.date} | Flags: #{flags}"
    }.join("\n")
  rescue Net::IMAP::Error, Errno::ECONNREFUSED, SocketError => e
    "Error connecting to mail server: #{e.message}"
  ensure
    imap&.logout rescue nil
  end

  private

  def connect
    imap = Net::IMAP.new(@config["imap_host"], port: @config["imap_port"], ssl: @config["imap_port"] == 993)
    imap.login(@config["email"], @config["password"])
    imap
  end
end
