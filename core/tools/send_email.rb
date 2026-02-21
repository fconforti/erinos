# frozen_string_literal: true

class SendEmail < RubyLLM::Tool
  description "Sends an email on behalf of the user."

  param :to, desc: "Recipient email address"
  param :subject, desc: "Email subject line"
  param :body, desc: "Email body text"

  def initialize(mail_config: nil, user: nil, **)
    @config = mail_config
    @user = user
  end

  def execute(to:, subject:, body:)
    return "Error: mail not configured. Ask the user to set up mail first." unless @config
    if @user && !@user.user_contacts.exists?(email: to)
      return "Error: #{to} is not in the user's contacts. Ask the user to add them as a contact first."
    end

    mail = Mail.new
    mail.from    = @config["email"]
    mail.to      = to
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

    "Email sent to #{to}."
  end
end
