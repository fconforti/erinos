# frozen_string_literal: true

require "bundler/setup"
Bundler.require

loader = Zeitwerk::Loader.new
loader.push_dir(File.expand_path("../entities", __dir__))
loader.push_dir(File.expand_path("../services", __dir__))
loader.push_dir(File.expand_path("../tools", __dir__))
loader.collapse(File.expand_path("../tools/contacts", __dir__))
loader.collapse(File.expand_path("../tools/emails", __dir__))
loader.collapse(File.expand_path("../tools/utils", __dir__))
loader.push_dir(File.expand_path("../lib", __dir__))
loader.setup

ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: File.expand_path("../db/data/erinos.sqlite3", __dir__)
)

TOOL_CATALOG = Dir[File.expand_path("../tools/**/*.rb", __dir__)].to_h { |path|
  name = File.basename(path, ".rb")
  group = File.dirname(path).then { |d| d == File.expand_path("../tools", __dir__) ? nil : File.basename(d) }
  [name, { klass: name.camelize.constantize, group: group }]
}.freeze
