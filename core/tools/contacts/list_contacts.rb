# frozen_string_literal: true

class ListContacts < RubyLLM::Tool
  include ContactSupport

  description "Lists all contacts for the user."

  def execute
    return msg if (msg = require_user!)

    contacts = @user.user_contacts.order(:last_name, :first_name)
    return "No contacts found." if contacts.empty?

    contacts.map { |c|
      line = "#{c.first_name} #{c.last_name} <#{c.email}>"
      line += " | #{c.phone}" if c.phone.present?
      line
    }.join("\n")
  end
end
