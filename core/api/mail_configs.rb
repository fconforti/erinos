# frozen_string_literal: true

class MailConfigsAPI < BaseAPI
  get "/users/:user_id/mail-config" do
    user = find_user!
    config = user.user_mail_config
    halt 404, { error: "not configured" }.to_json unless config
    serialize(config)
  end

  patch "/users/:user_id/mail-config" do
    user = find_user!
    data = json_body
    config = user.user_mail_config || user.build_user_mail_config
    config.assign_attributes(data.slice(:email, :imap_host, :imap_port, :smtp_host, :smtp_port, :password))
    halt 422, { errors: config.errors.full_messages }.to_json unless config.save
    serialize(config)
  end

  delete "/users/:user_id/mail-config" do
    user = find_user!
    config = user.user_mail_config
    halt 404, { error: "not configured" }.to_json unless config
    config.destroy
    [204, ""]
  end

  private

  def find_user!
    if params[:user_id] == "me"
      current_user
    else
      User.find(params[:user_id])
    end
  rescue ActiveRecord::RecordNotFound
    halt 404, { error: "not found" }.to_json
  end

  def serialize(config)
    {
      email: config.email,
      imap_host: config.imap_host,
      imap_port: config.imap_port,
      smtp_host: config.smtp_host,
      smtp_port: config.smtp_port
    }.to_json
  end
end
