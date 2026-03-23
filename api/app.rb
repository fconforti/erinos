require "sinatra/base"
require "json"

module Erinos
  class API < Sinatra::Base
    set :default_content_type, "application/json"

    get "/" do
      { status: "ok", app: "erinos" }.to_json
    end
  end
end
