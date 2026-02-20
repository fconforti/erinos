# frozen_string_literal: true

require "bundler/setup"
Bundler.require

loader = Zeitwerk::Loader.new
loader.push_dir(File.expand_path("../entities", __dir__))
loader.push_dir(File.expand_path("../services", __dir__))
loader.push_dir(File.expand_path("../tools", __dir__))
loader.setup

ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: File.expand_path("../db/data/erinos.sqlite3", __dir__)
)

smtp_user = ENV["SMTP_USER"].to_s.strip
Mail.defaults do
  delivery_method :smtp, {
    address: ENV.fetch("SMTP_HOST", "localhost"),
    port: ENV.fetch("SMTP_PORT", 1025).to_i,
    user_name: smtp_user.empty? ? nil : smtp_user,
    password: smtp_user.empty? ? nil : ENV["SMTP_PASSWORD"],
    authentication: smtp_user.empty? ? false : :plain,
    enable_starttls_auto: !smtp_user.empty?
  }
end

TOOL_CATALOG = Dir[File.expand_path("../tools/*.rb", __dir__)].to_h { |path|
  name = File.basename(path, ".rb")
  [name, name.classify.constantize]
}.freeze
