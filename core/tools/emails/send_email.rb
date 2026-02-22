# frozen_string_literal: true

class SendEmail < RubyLLM::Tool
  include EmailSupport

  description "Sends an email on behalf of the user."

  param :to, desc: "Recipient email address"
  param :subject, desc: "Email subject line"
  param :body, desc: "Email body text"

  def execute(to:, subject:, body:)
    return error if (error = require_config!)
    return error if (error = require_contact!(to))

    mail = Mail.new
    mail.from    = @config["email"]
    mail.to      = to
    mail.subject = subject
    mail.body    = body
    mail.delivery_method :smtp, smtp_settings

    mail.deliver

    "Email sent to #{to}."
  end
end
