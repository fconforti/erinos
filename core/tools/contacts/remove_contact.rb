# frozen_string_literal: true

class RemoveContact < RubyLLM::Tool
  description "Removes a contact by email address."

  param :email, desc: "Email of the contact to remove"

  def initialize(user: nil, **)
    @user = user
  end

  def execute(email:)
    return "Error: user context not available." unless @user

    contact = @user.user_contacts.find_by(email: email)
    return "Error: no contact found with email #{email}." unless contact

    name = "#{contact.first_name} #{contact.last_name}"
    contact.destroy
    "Contact removed: #{name} (#{email})"
  end
end
