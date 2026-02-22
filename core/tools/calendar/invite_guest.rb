# frozen_string_literal: true

class InviteGuest < RubyLLM::Tool
  include CalendarSupport

  description "Adds a guest to an existing Google Calendar event. Sends an invitation email to the guest."

  param :event_id, desc: "The event ID to add the guest to", required: true
  param :email, desc: "The guest's email address", required: true

  def execute(event_id:, email:)
    return msg if (msg = require_calendar!)

    service = calendar_service
    event = service.get_event("primary", event_id)

    attendees = event.attendees || []
    return "#{email} is already invited to this event." if attendees.any? { |a| a.email == email }

    attendees << Google::Apis::CalendarV3::EventAttendee.new(email: email)
    event.attendees = attendees

    result = service.update_event("primary", event_id, event, send_updates: "all")
    "Invited #{email} to #{result.summary}. An invitation email has been sent."
  rescue Google::Apis::Error => e
    "Error inviting guest: #{e.message}"
  end
end
