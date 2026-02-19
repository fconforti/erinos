# frozen_string_literal: true

require "bundler/setup"
Bundler.require

loader = Zeitwerk::Loader.new
loader.push_dir(File.expand_path("../entities", __dir__))
loader.push_dir(File.expand_path("../services", __dir__))
loader.setup

ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: File.expand_path("../db/data/erinos.sqlite3", __dir__)
)
