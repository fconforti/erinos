#!/usr/bin/env python3
"""TTS service using Chatterbox Turbo with Erin voice cloning.

Usage:
  Standalone:  python synthesize.py "Text to speak"
  From API:    python synthesize.py --job-id 1 --db path/to/erinos.sqlite3

Splits text into chunks, generates audio per chunk, concatenates into final WAV.
Updates job status in the database when running via API.
"""

import warnings
warnings.filterwarnings("ignore", category=FutureWarning)

import os
os.environ["TQDM_DISABLE"] = "1"
os.environ["TOKENIZERS_PARALLELISM"] = "false"

import sys
import re
import uuid
import argparse
import sqlite3
import json

import torch
import numpy as np
import torchaudio as ta
import soundfile as sf

# Patch: PerthImplicitWatermarker is unavailable on non-CUDA platforms
import perth
if perth.PerthImplicitWatermarker is None:
    perth.PerthImplicitWatermarker = perth.DummyWatermarker

from chatterbox.tts_turbo import ChatterboxTurboTTS

SERVICE_DIR = os.path.dirname(__file__)
ARTIFACTS_DIR = os.path.join(SERVICE_DIR, "..", "..", "artifacts", "tts")
REF_AUDIO = os.path.join(SERVICE_DIR, "ref", "erin_voice.wav")
CHATTERBOX_DIR = os.path.join(SERVICE_DIR, "chatterbox")


def detect_device():
    if torch.cuda.is_available():
        return "cuda"
    elif torch.backends.mps.is_available():
        return "mps"
    else:
        return "cpu"


def load_model():
    device = detect_device()
    return ChatterboxTurboTTS.from_local(CHATTERBOX_DIR, device=device)


def chunk_text(text, max_chars=200):
    """Split text into chunks at sentence boundaries."""
    sentences = re.split(r'(?<=[.!?])\s+', text.strip())
    chunks = []
    current = ""

    for sentence in sentences:
        if current and len(current) + len(sentence) > max_chars:
            chunks.append(current.strip())
            current = sentence
        else:
            current = f"{current} {sentence}".strip()

    if current:
        chunks.append(current.strip())

    return chunks


def update_job(db_path, job_id, **fields):
    """Update job fields in the database."""
    if not db_path or not job_id:
        return
    conn = sqlite3.connect(db_path)
    sets = ", ".join(f"{k} = ?" for k in fields)
    values = list(fields.values())
    conn.execute(f"UPDATE jobs SET {sets}, updated_at = datetime('now') WHERE id = ?", values + [job_id])
    conn.commit()
    conn.close()


def synthesize(model, text, temperature=0.8, job_id=None, db_path=None):
    """Clone Erin's voice to speak the given text. Returns final output file path."""
    chunks = chunk_text(text)
    total = len(chunks)

    # Create job output directory
    output_id = str(job_id) if job_id else uuid.uuid4().hex
    output_dir = os.path.join(ARTIFACTS_DIR, output_id)
    os.makedirs(output_dir, exist_ok=True)

    update_job(db_path, job_id, status="processing", total=total, progress=0)

    # Pre-compute voice conditionals for reuse across chunks
    model.prepare_conditionals(REF_AUDIO)

    chunk_paths = []

    for i, chunk in enumerate(chunks):
        wav = model.generate(chunk, temperature=temperature)

        chunk_path = os.path.join(output_dir, f"chunk_{i + 1:03d}.wav")
        ta.save(chunk_path, wav, model.sr)
        chunk_paths.append(chunk_path)

        update_job(db_path, job_id, progress=i + 1)

    # Concatenate all chunks into final WAV
    all_audio = []
    for path in chunk_paths:
        audio, _ = sf.read(path)
        all_audio.append(audio)

    combined = np.concatenate(all_audio)
    final_path = os.path.join(output_dir, "final.wav")
    sf.write(final_path, combined, model.sr)

    result = {"file": final_path, "chunks": chunk_paths}
    update_job(db_path, job_id, status="done", result=json.dumps(result))

    return final_path


def retry_chunks(model, job_id, chunk_numbers, temperature=0.8, db_path=None):
    """Re-generate specific chunks and re-concatenate final WAV."""
    # Read original job params to get the text
    conn = sqlite3.connect(db_path)
    row = conn.execute("SELECT params, result FROM jobs WHERE id = ?", (job_id,)).fetchone()
    conn.close()
    if not row:
        raise ValueError(f"Job {job_id} not found")

    params = json.loads(row[0])
    result = json.loads(row[1])
    text = params["text"]
    chunk_paths = result["chunks"]

    chunks = chunk_text(text)
    output_dir = os.path.dirname(chunk_paths[0])

    update_job(db_path, job_id, status="processing", total=len(chunk_numbers), progress=0)

    model.prepare_conditionals(REF_AUDIO)

    for progress, chunk_num in enumerate(chunk_numbers):
        idx = chunk_num - 1  # 1-based to 0-based
        if idx < 0 or idx >= len(chunks):
            raise ValueError(f"Chunk {chunk_num} out of range (1-{len(chunks)})")

        wav = model.generate(chunks[idx], temperature=temperature)

        chunk_path = os.path.join(output_dir, f"chunk_{chunk_num:03d}.wav")
        ta.save(chunk_path, wav, model.sr)

        update_job(db_path, job_id, progress=progress + 1)

    # Re-concatenate all chunks
    all_audio = []
    for path in chunk_paths:
        audio, _ = sf.read(path)
        all_audio.append(audio)

    combined = np.concatenate(all_audio)
    final_path = os.path.join(output_dir, "final.wav")
    sf.write(final_path, combined, model.sr)

    result["file"] = final_path
    update_job(db_path, job_id, status="done", result=json.dumps(result))

    return final_path


def main():
    parser = argparse.ArgumentParser(description="Erin TTS voice cloning (Chatterbox)")
    parser.add_argument("text", nargs="?", help="Text to synthesize")
    parser.add_argument("--job-id", type=int, help="Job ID (for API mode)")
    parser.add_argument("--db", help="Path to SQLite database (for API mode)")
    parser.add_argument("--temperature", type=float, default=0.8, help="Temperature (default: 0.8)")
    parser.add_argument("--retry-chunks", help="Comma-separated chunk numbers to retry (e.g. 2,4)")
    args = parser.parse_args()

    temperature = args.temperature

    # Retry mode
    if args.retry_chunks and args.job_id and args.db:
        chunk_numbers = [int(c) for c in args.retry_chunks.split(",")]
        try:
            model = load_model()
            path = retry_chunks(model, args.job_id, chunk_numbers, temperature=temperature, db_path=args.db)
            print(path)
        except Exception as e:
            update_job(args.db, args.job_id, status="failed", error=str(e))
            raise
        return

    # In API mode, read text from the job's params
    if args.job_id and args.db:
        conn = sqlite3.connect(args.db)
        row = conn.execute("SELECT params FROM jobs WHERE id = ?", (args.job_id,)).fetchone()
        conn.close()
        if not row:
            print(f"Job {args.job_id} not found", file=sys.stderr)
            sys.exit(1)
        params = json.loads(row[0])
        text = params["text"]
        temperature = params.get("temperature", temperature)
    elif args.text:
        text = args.text
    else:
        parser.print_help()
        sys.exit(1)

    try:
        model = load_model()
        path = synthesize(model, text, temperature=temperature, job_id=args.job_id, db_path=args.db)
        print(path)
    except Exception as e:
        if args.job_id and args.db:
            update_job(args.db, args.job_id, status="failed", error=str(e))
        raise


if __name__ == "__main__":
    main()
