module Erinos
  class API
    post "/api/tts" do
      body = JSON.parse(request.body.read)
      text = body["text"]

      halt 400, { error: "text is required" }.to_json if text.nil? || text.strip.empty?

      job_params = { text: text }
      job_params[:temperature] = body["temperature"].to_f if body["temperature"]

      job = Job.create!(
        service: "tts",
        status: "queued",
        params: job_params
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

    post "/api/tts/jobs/:id/retry" do
      body = JSON.parse(request.body.read)
      chunks = body["chunks"]

      halt 400, { error: "chunks is required (array of chunk numbers)" }.to_json if chunks.nil? || !chunks.is_a?(Array)

      job = Job.find_by(id: params[:id])
      halt 404, { error: "job not found" }.to_json unless job
      halt 400, { error: "job is not done" }.to_json unless job.status == "done"

      script = File.join(SERVICES_DIR, "tts", "synthesize.py")
      venv_python = File.join(SERVICES_DIR, "tts", "venv", "bin", "python")
      db_path = DB_PATH

      args = [venv_python, script, "--job-id", job.id.to_s, "--db", db_path,
              "--retry-chunks", chunks.join(",")]
      args += ["--temperature", body["temperature"].to_s] if body["temperature"]

      Thread.new do
        Open3.popen3(*args) do |_in, _out, _err, wait|
          wait.value
        end
      end

      status 202
      { job_id: job.id, status: "retrying", chunks: chunks }.to_json
    end
  end
end
