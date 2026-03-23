# ErinOS

Monorepo for ErinOS services.

## Structure

```
api/          Sinatra API (Ruby) — the core
services/     Local backends (Python scripts, CLIs)
cli/          Thor CLI — wraps the API for terminal use
artifacts/    Service outputs (gitignored)
```

## API

Sinatra app on port 9292. Routes are auto-loaded from `api/routes/`.

### `GET /`

Health check.

```json
{ "status": "ok", "app": "erinos" }
```

### `POST /api/tts`

Text-to-speech. Calls the TTS service, returns the path to the generated WAV file.

**Request:**

```json
{ "text": "Hello world" }
```

**Response:**

```json
{ "file": "/path/to/artifacts/tts/abc123.wav" }
```

## Services

Each service lives in `services/<name>/` with its own dependencies and venv.

### TTS (`services/tts/`)

Uses Qwen3 TTS. Takes text as an argument, writes WAV to `artifacts/tts/`.

```bash
cd services/tts
python3 -m venv venv
venv/bin/pip install -r requirements.txt
```

## CLI

Thor-based CLI that talks to the API over HTTP.

```bash
cd cli
bundle install
ruby erinos.rb tts "Hello world"
```

## Setup

```bash
# 1. TTS service
cd services/tts
python3 -m venv venv
venv/bin/pip install -r requirements.txt

# 2. API
cd ../../api
bundle install
bundle exec rackup

# 3. CLI (separate terminal)
cd ../cli
bundle install
ruby erinos.rb tts "Hello world"
```
