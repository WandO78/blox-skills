# Audio — local-first, premium fallback

Default to the FREE/LOCAL tier; escalate to ElevenLabs only for what local can't do.

TTS / narration:
- DEFAULT: Kokoro (local, free, Apache-2.0). `pip install kokoro` + espeak-ng. English voices strongest.
  Or via fal.ai: generate.py `--task tts` (fal-ai/kokoro/american-english).
- ESCALATE to ElevenLabs (`ELEVENLABS_API_KEY`) for cloned/expressive/premium voices or weak languages.

Transcription / STT (for captions, or feeding video-use):
- DEFAULT: Parakeet v3 (local, free, CC-BY-4.0; 25 EU langs incl. Hungarian; word timestamps; runs on
  Apple Silicon via `parakeet-mlx`). No diarization.
- ESCALATE to ElevenLabs Scribe when you need speaker DIARIZATION (who-spoke-when, up to 32),
  audio-event tags, AUDIO ISOLATION (denoise), DUBBING, or forced alignment.
Note: ElevenLabs "isolation" = voice vs background (one clean track), NOT per-speaker stems.

Always check /blox:setup doctor for the relevant key/package before running.
