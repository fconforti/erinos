# frozen_string_literal: true

class CreateEvent < RubyLLM::Tool
  include CalendarSupport

  description "Creates a new event on the user's Google Calendar."

  param :summary, desc: "Event title", required: true
  param :start_time, desc: "Start time in ISO 8601 format (e.g. 2026-02-23T10:00:00)", required: true
  param :end_time, desc: "End time in ISO 8601 format (e.g. 2026-02-23T11:00:00)", required: true
  param :description, desc: "Event description", required: false
  param :location, desc: "Event location", required: false

  def execute(summary:, start_time:, end_time:, description: nil, location: nil)
    return error if (error = require_calendar!)

    event = Google::Apis::CalendarV3::Event.new(
      summary: summary,
      start: Google::Apis::CalendarV3::EventDateTime.new(date_time: start_time),
      end: Google::Apis::CalendarV3::EventDateTime.new(date_time: end_time),
      description: description,
      location: location
    )

    result = calendar_service.insert_event("primary", event)
    "Event created: #{result.summary} (#{result.start.date_time}) | ID: #{result.id}"
  rescue Google::Apis::Error => e
    "Error creating event: #{e.message}"
  end
end
