# frozen_string_literal: true

class RemoveGuest < RubyLLM::Tool
  include CalendarSupport

  description "Removes a guest from an existing Google Calendar event. Sends a cancellation email to the guest."

  param :event_id, desc: "The event ID to remove the guest from", required: true
  param :email, desc: "The guest's email address", required: true

  def execute(event_id:, email:)
    return msg if (msg = require_calendar!)

    service = calendar_service
    event = service.get_event("primary", event_id)

    attendees = event.attendees || []
    return "#{email} is not a guest on this event." unless attendees.any? { |a| a.email == email }

    event.attendees = attendees.reject { |a| a.email == email }

    result = service.update_event("primary", event_id, event, send_updates: "all")
    "Removed #{email} from #{result.summary}. A cancellation email has been sent."
  rescue Google::Apis::Error => e
    "Error removing guest: #{e.message}"
  end
end
