# frozen_string_literal: true

class DeleteEvent < RubyLLM::Tool
  include CalendarSupport

  description "Deletes an event from the user's Google Calendar."

  param :event_id, desc: "The event ID to delete", required: true

  def execute(event_id:)
    return error if (error = require_calendar!)

    calendar_service.delete_event("primary", event_id)
    "Event deleted."
  rescue Google::Apis::Error => e
    "Error deleting event: #{e.message}"
  end
end
