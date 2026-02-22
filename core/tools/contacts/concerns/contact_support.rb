# frozen_string_literal: true

module ContactSupport
  def initialize(user: nil, **)
    @user = user
  end

  private

  def require_user!
    "Error: user context not available." unless @user
  end
end
