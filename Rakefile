require "active_record"
require_relative "db/config"

MIGRATIONS_DIR = File.expand_path("db/migrate", __dir__)

namespace :db do
  desc "Create the database"
  task :create do
    FileUtils.mkdir_p(DB_DIR)
    ActiveRecord::Base.establish_connection(
      adapter: "sqlite3",
      database: DB_PATH
    )
    puts "Database created at #{DB_PATH}"
  end

  desc "Run pending migrations"
  task :migrate do
    ActiveRecord::MigrationContext.new(MIGRATIONS_DIR).migrate
    puts "Migrations complete."
  end

  desc "Rollback the last migration"
  task :rollback do
    ActiveRecord::MigrationContext.new(MIGRATIONS_DIR).rollback
    puts "Rolled back."
  end

  desc "Show migration status"
  task :status do
    ActiveRecord::MigrationContext.new(MIGRATIONS_DIR).migrations_status.each do |status, version, name|
      puts "#{status.center(8)} #{version.ljust(14)} #{name}"
    end
  end

  desc "Drop the database"
  task :drop do
    if File.exist?(DB_PATH)
      File.delete(DB_PATH)
      puts "Database dropped."
    else
      puts "Database does not exist."
    end
  end

  desc "Reset: drop, create, migrate"
  task reset: [:drop, :create, :migrate]
end
