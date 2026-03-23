#!/usr/bin/env python3
"""TTS service using Qwen3 TTS.

Usage: python synthesize.py "Text to speak"

Writes WAV to artifacts/tts/ and prints the file path to stdout.
"""

import sys
import os
import io
import uuid
import soundfile as sf

# TODO: replace with actual Qwen3 TTS imports and model loading
# from transformers import AutoTokenizer, AutoModel

ARTIFACTS_DIR = os.path.join(os.path.dirname(__file__), "..", "..", "artifacts", "tts")


def synthesize(text: str) -> str:
    """Convert text to WAV audio, returns the output file path."""
    # TODO: load model and generate audio
    # model = ...
    # audio_array = model.generate(text)
    #
    # For now, placeholder that returns a silent WAV
    import numpy as np

    sample_rate = 24000
    duration = 0.1  # seconds
    samples = np.zeros(int(sample_rate * duration), dtype=np.float32)

    os.makedirs(ARTIFACTS_DIR, exist_ok=True)
    filename = f"{uuid.uuid4().hex}.wav"
    output_path = os.path.join(ARTIFACTS_DIR, filename)

    sf.write(output_path, samples, sample_rate, format="WAV")
    return output_path


def main():
    if len(sys.argv) < 2:
        print("Usage: synthesize.py <text>", file=sys.stderr)
        sys.exit(1)

    text = sys.argv[1]
    path = synthesize(text)
    print(path)


if __name__ == "__main__":
    main()
