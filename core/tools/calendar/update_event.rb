# frozen_string_literal: true

class UpdateEvent < RubyLLM::Tool
  include CalendarSupport

  description "Updates an existing event on the user's Google Calendar."

  param :event_id, desc: "The event ID to update", required: true
  param :summary, desc: "New event title", required: false
  param :start_time, desc: "New start time in ISO 8601 format", required: false
  param :end_time, desc: "New end time in ISO 8601 format", required: false
  param :description, desc: "New event description", required: false
  param :location, desc: "New event location", required: false

  def execute(event_id:, summary: nil, start_time: nil, end_time: nil, description: nil, location: nil)
    return error if (error = require_calendar!)

    existing = calendar_service.get_event("primary", event_id)

    existing.summary = summary if summary
    existing.start = Google::Apis::CalendarV3::EventDateTime.new(date_time: start_time) if start_time
    existing.end = Google::Apis::CalendarV3::EventDateTime.new(date_time: end_time) if end_time
    existing.description = description if description
    existing.location = location if location

    result = calendar_service.update_event("primary", event_id, existing)
    "Event updated: #{result.summary} (#{result.start.date_time || result.start.date}) | ID: #{result.id}"
  rescue Google::Apis::Error => e
    "Error updating event: #{e.message}"
  end
end
