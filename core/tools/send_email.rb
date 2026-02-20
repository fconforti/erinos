# frozen_string_literal: true

class SendEmail < RubyLLM::Tool
  description "Sends an email to the user. Use this to deliver summaries, reminders, or any information the user requests by email."

  param :subject, desc: "Email subject line"
  param :body, desc: "Email body text"

  def initialize(email: nil, **)
    @email = email
  end

  def execute(subject:, body:)
    return "Error: user has no email address configured." unless @email

    recipient = @email
    mail_subject = subject
    mail_body = body

    Mail.deliver do
      from    ENV.fetch("SMTP_FROM")
      to      recipient
      subject mail_subject
      body    mail_body
    end

    "Email sent to #{@email}."
  end
end
