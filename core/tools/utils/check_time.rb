# frozen_string_literal: true

class CheckTime < RubyLLM::Tool
  description "Returns the current date and time for the user"

  def initialize(timezone: "UTC", **)
    @timezone = timezone
  end

  def execute
    tz = TZInfo::Timezone.get(@timezone)
    tz.now.strftime("%Y-%m-%d %H:%M:%S %Z")
  end
end
