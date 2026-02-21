# frozen_string_literal: true

class SendEmail < RubyLLM::Tool
  description "Sends an email to the user. Use this to deliver summaries, reminders, or any information the user requests by email."

  param :subject, desc: "Email subject line"
  param :body, desc: "Email body text"

  def initialize(mail_config: nil, **)
    @config = mail_config
  end

  def execute(subject:, body:)
    return "Error: mail not configured. Ask the user to set up mail first." unless @config

    mail = Mail.new
    mail.from    = @config["email"]
    mail.to      = @config["email"]
    mail.subject = subject
    mail.body    = body

    mail.delivery_method :smtp, {
      address: @config["smtp_host"],
      port: @config["smtp_port"],
      user_name: @config["email"],
      password: @config["password"],
      authentication: :plain,
      enable_starttls_auto: true
    }

    mail.deliver

    "Email sent to #{@config['email']}."
  end
end
