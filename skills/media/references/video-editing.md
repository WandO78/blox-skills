# Video editing (real footage) — via video-use

Use when the user has their OWN footage to cut/assemble (e.g. "edit these clips into a 3-min video").
Tool: video-use (transcript-driven editor). Prereq: `ffmpeg` + `ELEVENLABS_API_KEY`; clone at `~/Developer/video-use`
(see /blox:setup doctor). It is itself a skill — drive it per its SKILL.md. Flow:

1. Drop source files in a folder. Transcribe: `python helpers/transcribe_batch.py <dir>`
2. Pack transcripts: `python helpers/pack_transcripts.py --edit-dir <dir>/edit`
3. The agent reads the packed transcript and writes an EDL (`edl.json`: source/start/end/reason ranges) —
   cut filler, pick best takes, order beats.
4. Render: `python helpers/render.py edl.json -o final.mp4 --build-subtitles`
   (grade + 30ms fades + subtitles + -14 LUFS loudnorm). Overlays/animation come from HyperFrames
   (see animation-render.md) — video-use composites them.
Generated b-roll/clips from generate.py (image_to_video) can be added as additional sources.
