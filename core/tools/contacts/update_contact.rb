# frozen_string_literal: true

class UpdateContact < RubyLLM::Tool
  include ContactSupport

  description "Updates an existing contact by email address."

  param :email, desc: "Current email of the contact to update"
  param :first_name, desc: "New first name (optional)", required: false
  param :last_name, desc: "New last name (optional)", required: false
  param :new_email, desc: "New email address (optional)", required: false
  param :phone, desc: "New phone number (optional)", required: false

  def execute(email:, first_name: nil, last_name: nil, new_email: nil, phone: nil)
    return msg if (msg = require_user!)

    contact = @user.user_contacts.find_by(email: email)
    return "Error: no contact found with email #{email}." unless contact

    attrs = {}
    attrs[:first_name] = first_name if first_name
    attrs[:last_name] = last_name if last_name
    attrs[:email] = new_email if new_email
    attrs[:phone] = phone if phone

    return "Nothing to update." if attrs.empty?

    contact.assign_attributes(attrs)
    return "Error: #{contact.errors.full_messages.join(', ')}" unless contact.save

    "Contact updated: #{contact.first_name} #{contact.last_name} <#{contact.email}>"
  end
end
