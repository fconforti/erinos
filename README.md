# ErinOS

Monorepo for ErinOS services.

## Structure

```
Gemfile        Shared Ruby dependencies
Rakefile       DB rake tasks
config.ru      Rack config
api/           Sinatra API (Ruby) — the core
  routes/      API route files (auto-loaded)
  models/      ActiveRecord models
services/      Local backends (Python scripts with venvs)
cli/           Thor CLI — wraps the API for terminal use
db/
  migrate/     ActiveRecord migrations
  data/        SQLite database (gitignored)
artifacts/     Service outputs, per-service subfolders (gitignored)
```

## API

Sinatra app on port 9292. Routes are auto-loaded from `api/routes/`.

### `GET /`

Health check.

```json
{ "status": "ok", "app": "erinos" }
```

### `POST /api/tts`

Text-to-speech. Creates an async job, returns a job ID.

**Request:**

```json
{ "text": "Hello world" }
```

**Response (202):**

```json
{ "job_id": 1, "status": "queued" }
```

### `GET /api/jobs/:id`

Check job status.

**Processing:**

```json
{ "job_id": 1, "service": "tts", "status": "processing", "progress": 3, "total": 12 }
```

**Done:**

```json
{ "job_id": 1, "service": "tts", "status": "done", "progress": 12, "total": 12,
  "result": { "file": "artifacts/tts/1/final.wav", "chunks": ["..."] } }
```

## Services

Each service lives in `services/<name>/` with its own venv. Services update a shared `jobs` table in SQLite.

### TTS (`services/tts/`)

Voice cloning with Qwen3 TTS (`Qwen3-TTS-12Hz-1.7B-Base`). Clones Erin's voice from a reference WAV in `services/tts/ref/`. Auto-detects device (CUDA, MPS, CPU). Splits long text into chunks and concatenates.

Requires `sox` (`brew install sox` on Mac).

```bash
cd services/tts
python3 -m venv venv
venv/bin/pip install -r requirements.txt
```

## CLI

Thor-based CLI that talks to the API over HTTP.

```bash
ruby cli/erinos.rb tts "Hello world"
```

## Setup

```bash
# 1. Ruby deps
bundle install

# 2. Database
bundle exec rake db:create db:migrate

# 3. TTS service
cd services/tts
python3 -m venv venv
venv/bin/pip install -r requirements.txt
cd ../..

# 4. Start the API
bundle exec rackup

# 5. Test (separate terminal)
curl -X POST http://localhost:9292/api/tts \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello world"}'
```
