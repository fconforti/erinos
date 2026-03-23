module Erinos
  class API
    post "/api/tts" do
      body = JSON.parse(request.body.read)
      text = body["text"]

      halt 400, { error: "text is required" }.to_json if text.nil? || text.strip.empty?

      job = Job.create!(
        service: "tts",
        status: "queued",
        params: { text: text }
      )

      script = File.join(SERVICES_DIR, "tts", "synthesize.py")
      venv_python = File.join(SERVICES_DIR, "tts", "venv", "bin", "python")
      db_path = DB_PATH

      Thread.new do
        Open3.popen3(venv_python, script, "--job-id", job.id.to_s, "--db", db_path) do |_in, _out, _err, wait|
          wait.value
        end
      end

      status 202
      { job_id: job.id, status: "queued" }.to_json
    end
  end
end
