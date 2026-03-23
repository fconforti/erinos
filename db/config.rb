require "active_record"

DB_DIR = File.expand_path("data", __dir__)
DB_PATH = File.join(DB_DIR, "erinos.sqlite3")

ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: DB_PATH
)
