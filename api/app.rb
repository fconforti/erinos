require "sinatra/base"
require "json"
require "open3"
require_relative "../db/config"
require_relative "models/job"

module Erinos
  class API < Sinatra::Base
    set :default_content_type, "application/json"

    SERVICES_DIR = File.expand_path("../services", __dir__)

    get "/" do
      { status: "ok", app: "erinos" }.to_json
    end

    get "/api/jobs/:id" do
      job = Job.find_by(id: params[:id])
      halt 404, { error: "job not found" }.to_json unless job

      response = {
        job_id: job.id,
        service: job.service,
        status: job.status,
        progress: job.progress,
        total: job.total
      }

      case job.status
      when "done"
        response[:result] = job.result
      when "failed"
        response[:error] = job.error
      end

      response.to_json
    end
  end
end

Dir[File.join(__dir__, "routes", "*.rb")].each { |f| require f }
