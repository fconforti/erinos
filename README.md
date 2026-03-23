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
{ "text": "Hello world", "temperature": 0.8 }
```

`temperature` is optional (default 0.8). Higher = more varied delivery, lower = more consistent.

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

### `POST /api/tts/jobs/:id/retry`

Re-generate specific chunks from an existing job.

**Request:**

```json
{ "chunks": [2, 4], "temperature": 0.6 }
```

**Response (202):**

```json
{ "job_id": 1, "status": "retrying", "chunks": [2, 4] }
```

## Services

Each service lives in `services/<name>/` with its own venv. Services update a shared `jobs` table in SQLite.

### TTS (`services/tts/`)

Voice cloning with Chatterbox Turbo (`ResembleAI/chatterbox-turbo`). Clones Erin's voice from a reference WAV in `services/tts/ref/`. Model weights stored locally in `services/tts/chatterbox/` (tracked with Git LFS). Auto-detects device (CUDA, MPS, CPU). Splits long text into chunks and concatenates.

```bash
cd services/tts
python3.11 -m venv venv
venv/bin/pip install -r requirements.txt
```

## CLI

Thor-based CLI that talks to the API over HTTP.

```bash
# Generate from text
ruby cli/erinos.rb tts "Hello world"

# Generate from file with custom temperature
ruby cli/erinos.rb tts -f script.txt -t 0.9

# Retry specific chunks
ruby cli/erinos.rb tts:retry 7 -c 2,4 -t 0.6
```

## Setup

```bash
# 1. Ruby deps
bundle install

# 2. Database
bundle exec rake db:create db:migrate

# 3. TTS service (requires Python 3.11)
cd services/tts
python3.11 -m venv venv
venv/bin/pip install -r requirements.txt
cd ../..

# 4. Start the API
bundle exec rackup

# 5. Test (separate terminal)
curl -X POST http://localhost:9292/api/tts \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello world"}'
```
