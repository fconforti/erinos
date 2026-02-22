# frozen_string_literal: true

class RemoveContact < RubyLLM::Tool
  include ContactSupport

  description "Removes a contact by email address."

  param :email, desc: "Email of the contact to remove"

  def execute(email:)
    return msg if (msg = require_user!)

    contact = @user.user_contacts.find_by(email: email)
    return "Error: no contact found with email #{email}." unless contact

    name = "#{contact.first_name} #{contact.last_name}"
    contact.destroy
    "Contact removed: #{name} (#{email})"
  end
end
