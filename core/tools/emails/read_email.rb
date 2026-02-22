# frozen_string_literal: true

class ReadEmail < RubyLLM::Tool
  include EmailSupport

  description "Reads the full content of an email by its UID. Use check_inbox or search_email first to find the UID."

  param :uid, desc: "The UID of the email to read"

  def execute(uid:)
    return error if (error = require_config!)

    imap = connect_imap
    imap.select("INBOX")

    data = imap.uid_fetch(uid.to_i, ["UID", "ENVELOPE", "BODY[]", "FLAGS"])
    return "Email not found." unless data&.first

    msg = data.first
    env = msg.attr["ENVELOPE"]
    raw = msg.attr["BODY[]"]
    mail = Mail.read_from_string(raw)

    from = env.from&.first
    sender = from ? "#{from.name || ''} <#{from.mailbox}@#{from.host}>" : "unknown"
    to = env.to&.map { |a| "#{a.mailbox}@#{a.host}" }&.join(", ") || "unknown"

    body = mail.text_part&.decoded || mail.body&.decoded || "(no body)"
    body = body.encode("UTF-8", invalid: :replace, undef: :replace, replace: "?")

    <<~EMAIL
      UID: #{msg.attr['UID']}
      From: #{sender}
      To: #{to}
      Subject: #{env.subject}
      Date: #{env.date}

      #{body}
    EMAIL
  rescue Net::IMAP::Error, Errno::ECONNREFUSED, SocketError => e
    "Error connecting to mail server: #{e.message}"
  ensure
    imap&.logout rescue nil
  end
end
