# frozen_string_literal: true

class CheckCalendar < RubyLLM::Tool
  include CalendarSupport

  description "Lists upcoming events from the user's Google Calendar."

  param :days, desc: "Number of days ahead to check (default 7)", required: false

  def execute(days: "7")
    return msg if (msg = require_calendar!)

    now = Time.now.iso8601
    time_max = (Time.now + days.to_i * 86_400).iso8601

    events = calendar_service.list_events(
      "primary",
      single_events: true,
      order_by: "startTime",
      time_min: now,
      time_max: time_max
    )

    return "No upcoming events." if events.items.nil? || events.items.empty?

    events.items.map { |e|
      start = e.start.date_time&.strftime("%Y-%m-%d %H:%M") || e.start.date
      finish = e.end.date_time&.strftime("%H:%M") || e.end.date
      parts = ["#{start}-#{finish}: #{e.summary}"]
      parts << "Location: #{e.location}" if e.location
      if e.attendees&.any?
        guests = e.attendees.map { |a| a.display_name || a.email }.join(", ")
        parts << "Guests: #{guests}"
      end
      parts << "ID: #{e.id}"
      parts.join(" | ")
    }.join("\n")
  rescue Google::Apis::Error => e
    "Error accessing Google Calendar: #{e.message}"
  end
end
