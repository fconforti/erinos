# frozen_string_literal: true

class CheckDrafts < RubyLLM::Tool
  include EmailSupport

  description "Lists draft emails, or reads a specific draft by UID."

  param :uid, desc: "UID of a draft to read in full (optional — omit to list all drafts)", required: false

  def execute(uid: nil)
    return msg if (msg = require_config!)

    imap = connect_imap
    drafts = find_drafts_folder(imap)
    imap.select(drafts)

    uid ? read_draft(imap, uid.to_i) : list_drafts(imap)
  rescue Net::IMAP::Error, Errno::ECONNREFUSED, SocketError => e
    "Error: #{e.message}"
  ensure
    imap&.logout rescue nil
  end

  private

  def list_drafts(imap)
    uids = imap.uid_search(["ALL"])
    return "No drafts found." if uids.empty?

    messages = imap.uid_fetch(uids, ["UID", "ENVELOPE"])

    messages.reverse.map { |msg|
      env = msg.attr["ENVELOPE"]
      to = env.to&.map { |a| "#{a.mailbox}@#{a.host}" }&.join(", ") || "unknown"
      "UID: #{msg.attr['UID']} | To: #{to} | Subject: #{env.subject} | Date: #{env.date}"
    }.join("\n")
  end

  def read_draft(imap, uid)
    data = imap.uid_fetch(uid, ["UID", "ENVELOPE", "BODY[]"])
    return "Draft not found." unless data&.first

    msg = data.first
    env = msg.attr["ENVELOPE"]
    mail = Mail.read_from_string(msg.attr["BODY[]"])

    to = env.to&.map { |a| "#{a.mailbox}@#{a.host}" }&.join(", ") || "unknown"
    body = mail.text_part&.decoded || mail.body&.decoded || "(no body)"
    body = body.encode("UTF-8", invalid: :replace, undef: :replace, replace: "?")

    <<~EMAIL
      UID: #{msg.attr['UID']}
      To: #{to}
      Subject: #{env.subject}
      Date: #{env.date}

      #{body}
    EMAIL
  end
end
