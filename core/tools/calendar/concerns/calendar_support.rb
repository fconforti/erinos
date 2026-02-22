# frozen_string_literal: true

module CalendarSupport
  def initialize(user: nil, **)
    @user = user
  end

  private

  def require_calendar!
    return "Error: user context not available." unless @user
    @google = @user.credential("google")&.data
    return "Error: Google Calendar not configured." unless @google
    return "Error: Google Calendar not authorized yet." unless @google["refresh_token"]
    nil
  end

  def calendar_service
    credentials = Google::Auth::UserRefreshCredentials.new(
      client_id: @google["client_id"],
      client_secret: @google["client_secret"],
      refresh_token: @google["refresh_token"],
      scope: "https://www.googleapis.com/auth/calendar"
    )
    credentials.fetch_access_token!
    service = Google::Apis::CalendarV3::CalendarService.new
    service.authorization = credentials
    service
  end
end
