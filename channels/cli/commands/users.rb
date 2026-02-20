# frozen_string_literal: true

require_relative "base"

module Commands
  class Users < Base
    namespace :users

    desc "link", "Generate a code to link another channel to your account"
    def link
      result = client.post("/identity-links", {})
      say "Link code: #{set_color(result['code'], :green, :bold)}"
      say "Enter this code from another channel within 5 minutes."
    end

    desc "claim CODE", "Link your identity to an existing account using a code"
    def claim(code)
      client.patch("/identity-links/#{code}", {})
      say set_color("Identity linked successfully.", :green)
    end
  end
end
