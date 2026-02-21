# frozen_string_literal: true

class AddContact < RubyLLM::Tool
  description "Adds a new contact for the user."

  param :first_name, desc: "Contact's first name"
  param :last_name, desc: "Contact's last name"
  param :email, desc: "Contact's email address"
  param :phone, desc: "Contact's phone number (optional)", required: false

  def initialize(user: nil, **)
    @user = user
  end

  def execute(first_name:, last_name:, email:, phone: nil)
    return "Error: user context not available." unless @user

    contact = @user.user_contacts.new(first_name: first_name, last_name: last_name, email: email, phone: phone)
    return "Error: #{contact.errors.full_messages.join(', ')}" unless contact.save

    "Contact added: #{first_name} #{last_name} (#{email})"
  end
end
