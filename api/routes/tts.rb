module Erinos
  class API
    post "/api/tts" do
      body = JSON.parse(request.body.read)
      text = body["text"]

      halt 400, { error: "text is required" }.to_json if text.nil? || text.strip.empty?

      script = File.join(SERVICES_DIR, "tts", "synthesize.py")
      venv_python = File.join(SERVICES_DIR, "tts", "venv", "bin", "python")

      stdout, stderr, status = Open3.capture3(venv_python, script, text)

      unless status.success?
        halt 500, { error: "TTS failed", details: stderr }.to_json
      end

      file_path = stdout.strip
      { file: file_path }.to_json
    end
  end
end
