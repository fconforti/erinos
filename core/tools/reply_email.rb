# frozen_string_literal: true

class ReplyEmail < RubyLLM::Tool
  include ImapSupport

  description "Replies to an email by its UID. Sends the reply to the original sender."

  param :uid, desc: "The UID of the email to reply to"
  param :body, desc: "The reply body text"

  def initialize(mail_config: nil, **)
    @config = mail_config
  end

  def execute(uid:, body:)
    return "Error: mail not configured. Ask the user to set up mail first." unless @config

    imap = connect_imap
    imap.select("INBOX")

    data = imap.uid_fetch(uid.to_i, ["ENVELOPE", "BODY[]"])
    return "Email not found." unless data&.first

    env = data.first.attr["ENVELOPE"]
    original = Mail.read_from_string(data.first.attr["BODY[]"])

    reply_to = original.reply_to&.first || "#{env.from.first.mailbox}@#{env.from.first.host}"
    original_subject = env.subject || ""
    subject = original_subject.start_with?("Re:") ? original_subject : "Re: #{original_subject}"

    reply = Mail.new
    reply.from    = @config["email"]
    reply.to      = reply_to
    reply.subject = subject
    reply.body    = body
    reply.in_reply_to = env.message_id
    reply.references  = env.message_id

    reply.delivery_method :smtp, {
      address: @config["smtp_host"],
      port: @config["smtp_port"],
      user_name: @config["email"],
      password: @config["password"],
      authentication: :plain,
      enable_starttls_auto: true
    }

    reply.deliver

    "Reply sent to #{reply_to}."
  rescue Net::IMAP::Error, Errno::ECONNREFUSED, SocketError => e
    "Error: #{e.message}"
  ensure
    imap&.logout rescue nil
  end
end
