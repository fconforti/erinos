#!/usr/bin/env python3
"""TTS service using Qwen3 TTS with Erin voice cloning.

Usage:
  Standalone:  python synthesize.py "Text to speak"
  From API:    python synthesize.py --job-id 1 --db path/to/erinos.sqlite3

Splits text into chunks, generates audio per chunk, concatenates into final WAV.
Updates job status in the database when running via API.
"""

import sys
import os
import re
import uuid
import argparse
import sqlite3
import json

import torch
import numpy as np
import soundfile as sf
from qwen_tts import Qwen3TTSModel

SERVICE_DIR = os.path.dirname(__file__)
ARTIFACTS_DIR = os.path.join(SERVICE_DIR, "..", "..", "artifacts", "tts")
REF_AUDIO = os.path.join(SERVICE_DIR, "ref", "erin_voice.wav")
REF_TEXT_FILE = os.path.join(SERVICE_DIR, "ref", "erin_text.txt")


def detect_device():
    if torch.cuda.is_available():
        return "cuda:0", torch.bfloat16
    elif torch.backends.mps.is_available():
        return "mps", torch.float32
    else:
        return "cpu", torch.float32


def load_model():
    device, dtype = detect_device()
    return Qwen3TTSModel.from_pretrained(
        "Qwen/Qwen3-TTS-12Hz-1.7B-Base",
        device_map=device,
        dtype=dtype,
    )


def chunk_text(text, max_chars=500):
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


def synthesize(model, text, job_id=None, db_path=None):
    """Clone Erin's voice. Returns final output file path."""
    with open(REF_TEXT_FILE) as f:
        ref_text = f.read().strip()

    chunks = chunk_text(text)
    total = len(chunks)

    # Create job output directory
    output_id = str(job_id) if job_id else uuid.uuid4().hex
    output_dir = os.path.join(ARTIFACTS_DIR, output_id)
    os.makedirs(output_dir, exist_ok=True)

    update_job(db_path, job_id, status="processing", total=total, progress=0)

    # Create reusable voice prompt
    prompt_items = model.create_voice_clone_prompt(
        ref_audio=REF_AUDIO,
        ref_text=ref_text,
    )

    chunk_paths = []
    sample_rate = None

    for i, chunk in enumerate(chunks):
        wavs, sr = model.generate_voice_clone(
            text=chunk,
            language="English",
            voice_clone_prompt=prompt_items,
        )
        sample_rate = sr

        chunk_path = os.path.join(output_dir, f"chunk_{i + 1:03d}.wav")
        sf.write(chunk_path, wavs[0], sr)
        chunk_paths.append(chunk_path)

        update_job(db_path, job_id, progress=i + 1)

    # Concatenate all chunks into final WAV
    all_audio = []
    for path in chunk_paths:
        audio, _ = sf.read(path)
        all_audio.append(audio)

    combined = np.concatenate(all_audio)
    final_path = os.path.join(output_dir, "final.wav")
    sf.write(final_path, combined, sample_rate)

    result = {"file": final_path, "chunks": chunk_paths}
    update_job(db_path, job_id, status="done", result=json.dumps(result))

    return final_path


def main():
    parser = argparse.ArgumentParser(description="Erin TTS voice cloning")
    parser.add_argument("text", nargs="?", help="Text to synthesize")
    parser.add_argument("--job-id", type=int, help="Job ID (for API mode)")
    parser.add_argument("--db", help="Path to SQLite database (for API mode)")
    args = parser.parse_args()

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
    elif args.text:
        text = args.text
    else:
        parser.print_help()
        sys.exit(1)

    try:
        model = load_model()
        path = synthesize(model, text, job_id=args.job_id, db_path=args.db)
        print(path)
    except Exception as e:
        if args.job_id and args.db:
            update_job(args.db, args.job_id, status="failed", error=str(e))
        raise


if __name__ == "__main__":
    main()
