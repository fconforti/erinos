# frozen_string_literal: true

class DraftEmail < RubyLLM::Tool
  include EmailSupport

  description "Creates a draft email and saves it to the user's Drafts folder for review. The user can send it from their email client."

  param :to, desc: "Recipient email address"
  param :subject, desc: "Email subject line"
  param :body, desc: "Email body text"

  def execute(to:, subject:, body:)
    return error if (error = require_config!)

    mail = Mail.new
    mail.from    = @config["email"]
    mail.to      = to
    mail.subject = subject
    mail.body    = body

    imap = connect_imap
    drafts = find_drafts_folder(imap)
    imap.append(drafts, mail.to_s, [:Draft])

    "Draft saved to your Drafts folder (to: #{to}, subject: #{subject}). Open your email client to review and send it."
  rescue Net::IMAP::Error, Errno::ECONNREFUSED, SocketError => e
    "Error: #{e.message}"
  ensure
    imap&.logout rescue nil
  end
end
