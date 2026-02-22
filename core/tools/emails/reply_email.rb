# frozen_string_literal: true

class ReplyEmail < RubyLLM::Tool
  include EmailSupport

  description "Replies to an email by its UID. Sends the reply to the original sender."

  param :uid, desc: "The UID of the email to reply to"
  param :body, desc: "The reply body text"

  def execute(uid:, body:)
    return error if (error = require_config!)

    imap = connect_imap
    imap.select("INBOX")

    data = imap.uid_fetch(uid.to_i, ["ENVELOPE", "BODY[]"])
    return "Email not found." unless data&.first

    env = data.first.attr["ENVELOPE"]
    original = Mail.read_from_string(data.first.attr["BODY[]"])

    reply_to = original.reply_to&.first || "#{env.from.first.mailbox}@#{env.from.first.host}"
    return error if (error = require_contact!(reply_to))
    original_subject = env.subject || ""
    subject = original_subject.start_with?("Re:") ? original_subject : "Re: #{original_subject}"

    reply = Mail.new
    reply.from    = @config["email"]
    reply.to      = reply_to
    reply.subject = subject
    reply.body    = body
    reply.in_reply_to = env.message_id
    reply.references  = env.message_id
    reply.delivery_method :smtp, smtp_settings

    reply.deliver

    "Reply sent to #{reply_to}."
  rescue Net::IMAP::Error, Errno::ECONNREFUSED, SocketError => e
    "Error: #{e.message}"
  ensure
    imap&.logout rescue nil
  end
end
