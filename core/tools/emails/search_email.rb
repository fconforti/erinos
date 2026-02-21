# frozen_string_literal: true

class SearchEmail < RubyLLM::Tool
  include ImapSupport

  description "Searches the user's inbox by keyword, sender, or subject. Returns matching emails with UIDs."

  param :from, desc: "Filter by sender email or name", required: false
  param :subject, desc: "Filter by subject keyword", required: false
  param :keyword, desc: "Search in the full email body and headers", required: false
  param :limit, desc: "Max results to return (default 10, max 50)", required: false

  def initialize(mail_config: nil, **)
    @config = mail_config
  end

  def execute(from: nil, subject: nil, keyword: nil, limit: "10")
    return "Error: mail not configured. Ask the user to set up mail first." unless @config
    return "Error: provide at least one search filter (from, subject, or keyword)." unless from || subject || keyword

    count = [[limit.to_i, 1].max, 50].min

    criteria = []
    criteria.push("FROM", from) if from
    criteria.push("SUBJECT", subject) if subject
    criteria.push("TEXT", keyword) if keyword

    imap = connect_imap
    imap.select("INBOX")

    uids = imap.uid_search(criteria)
    return "No emails found matching your search." if uids.empty?

    uids = uids.last(count)
    messages = imap.uid_fetch(uids, ["UID", "ENVELOPE", "FLAGS"])

    messages.reverse.map { |msg|
      env = msg.attr["ENVELOPE"]
      sender = env.from&.first
      sender_str = sender ? "#{sender.name || ''} <#{sender.mailbox}@#{sender.host}>" : "unknown"

      "UID: #{msg.attr['UID']} | From: #{sender_str} | Subject: #{env.subject} | Date: #{env.date}"
    }.join("\n")
  rescue Net::IMAP::Error, Errno::ECONNREFUSED, SocketError => e
    "Error connecting to mail server: #{e.message}"
  ensure
    imap&.logout rescue nil
  end
end
