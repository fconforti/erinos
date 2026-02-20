# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name    = "erinos-client"
  s.version = "0.1.0"
  s.summary = "HTTP client for the ErinOS Core API"
  s.authors = ["Filippo Conforti"]

  s.required_ruby_version = ">= 3.1"

  s.files = Dir["lib/**/*.rb"]

  s.add_dependency "faraday", "~> 2.12"
end
