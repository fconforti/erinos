require "sinatra/base"
require "json"
require "open3"

module Erinos
  class API < Sinatra::Base
    set :default_content_type, "application/json"

    SERVICES_DIR = File.expand_path("../services", __dir__)

    get "/" do
      { status: "ok", app: "erinos" }.to_json
    end
  end
end

Dir[File.join(__dir__, "routes", "*.rb")].each { |f| require f }
