# frozen_string_literal: true

class ListContacts < RubyLLM::Tool
  description "Lists all contacts for the user."

  def initialize(user: nil, **)
    @user = user
  end

  def execute
    return "Error: user context not available." unless @user

    contacts = @user.user_contacts.order(:last_name, :first_name)
    return "No contacts found." if contacts.empty?

    contacts.map { |c|
      line = "#{c.first_name} #{c.last_name} <#{c.email}>"
      line += " | #{c.phone}" if c.phone.present?
      line
    }.join("\n")
  end
end
