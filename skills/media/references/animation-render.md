# Animation & render — HTML→MP4

Primary engine: HyperFrames (agent-native, Apache-2.0). Use for motion graphics, kinetic captions,
lower-thirds, transitions, animated/scroll-embeddable decks, and final MP4 assembly.
Prereq: Node 22+ + ffmpeg (see /blox:setup doctor). In automated runs set `DO_NOT_TRACK=1`
and disable auto-update.

  npx hyperframes init <dir>      # scaffold an HTML composition
  npx hyperframes preview         # live browser preview
  npx hyperframes render -o out.mp4

Author the composition as index.html with timed `.clip` elements (`data-start`/`data-duration`/
`data-track-index`) and seekable timelines (GSAP/Lottie/CSS). For scroll-embeddable output use the
HyperFrames player web component.

Fallback (only if the project already uses Remotion): the 37 domain rule files in `remotion-rules/`
(load on demand) cover animations, captions, charts, 3D, transitions, audio. Prefer HyperFrames for new work.
