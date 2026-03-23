#!/usr/bin/env python3
"""TTS service using Qwen3 TTS with Erin voice cloning.

Usage: python synthesize.py "Text to speak"

Writes WAV to artifacts/tts/ and prints the file path to stdout.
"""

import sys
import os
import uuid

import torch
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


def synthesize(model, text: str) -> str:
    """Clone Erin's voice to speak the given text. Returns output file path."""
    with open(REF_TEXT_FILE) as f:
        ref_text = f.read().strip()

    wavs, sr = model.generate_voice_clone(
        text=text,
        language="English",
        ref_audio=REF_AUDIO,
        ref_text=ref_text,
    )

    os.makedirs(ARTIFACTS_DIR, exist_ok=True)
    filename = f"{uuid.uuid4().hex}.wav"
    output_path = os.path.join(ARTIFACTS_DIR, filename)

    sf.write(output_path, wavs[0], sr)
    return output_path


def main():
    if len(sys.argv) < 2:
        print("Usage: synthesize.py <text>", file=sys.stderr)
        sys.exit(1)

    text = sys.argv[1]
    model = load_model()
    path = synthesize(model, text)
    print(path)


if __name__ == "__main__":
    main()
