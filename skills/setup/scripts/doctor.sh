#!/bin/bash
# blox design/media prerequisites doctor. Reports present/missing + fix.
# Usage: ./doctor.sh    Exit 0 always (informational).
ok(){ printf "  \033[32m✓\033[0m %s\n" "$1"; }
no(){ printf "  \033[31m✗\033[0m %s\n     fix: %s\n" "$1" "$2"; }

echo "=== blox doctor: companions + media/build prerequisites ==="
echo "blox companions (install via /plugin):"
companion(){ # $1=name $2=note
  if ls -d "$HOME"/.claude/plugins/cache/*/"$1" >/dev/null 2>&1; then
    ok "$1 — $2"
  else
    no "$1 missing — $2" "/plugin install $1"
  fi
}
companion superpowers   "methodology pillar blox defers to (STRONGLY recommended)"
companion frontend-design "production frontend handoff from /blox:ui"
companion plannotator   "plan/code annotation UI (optional)"
echo "API keys:"
[ -n "$FAL_KEY" ] && ok "FAL_KEY set" || no "FAL_KEY missing (fal.ai generation)" "export FAL_KEY=... in ~/.zshrc"
[ -n "$ELEVENLABS_API_KEY" ] && ok "ELEVENLABS_API_KEY set" || no "ELEVENLABS_API_KEY missing (diarization/dubbing/premium TTS/video-use)" "export ELEVENLABS_API_KEY=..."
echo "System tools:"
command -v ffmpeg >/dev/null   && ok "ffmpeg"   || no "ffmpeg missing"   "brew install ffmpeg"
command -v node >/dev/null     && ok "node $(node -v 2>/dev/null)" || no "node missing (need 22+)" "brew install node"
command -v python3 >/dev/null  && ok "python3 $(python3 -V 2>&1 | awk '{print $2}')" || no "python3 missing" "brew install python"
command -v espeak-ng >/dev/null && ok "espeak-ng" || no "espeak-ng missing (Kokoro TTS)" "brew install espeak-ng"
command -v git >/dev/null      && ok "git"      || no "git missing"      "xcode-select --install"
echo "Python packages:"
for p in fal_client kokoro parakeet_mlx; do
  python3 -c "import $p" 2>/dev/null && ok "$p" || no "$p not installed" "pip install ${p//_/-}"
done
echo "Components:"
[ -d "$HOME/Developer/video-use" ] && ok "video-use cloned" || no "video-use not cloned" "git clone https://github.com/browser-use/video-use ~/Developer/video-use"
echo "=== done — nothing blocks; install missing items via the fix commands above ==="
