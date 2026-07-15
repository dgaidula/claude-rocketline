#!/usr/bin/env bash
# Showcase every theme × cap style, in real color.
# Usage:  bash demos/showcase.sh
SL="${STATUSLINE_SH:-$(cd "$(dirname "$0")/.." && pwd)/statusline.sh}"

DEMO="/tmp/ccsl-demo/my-app"
if [ ! -e "$DEMO/.git" ]; then
  mkdir -p "$DEMO"
  ( unset GIT_DIR GIT_WORK_TREE
    git init -q "$DEMO" 2>/dev/null
    git -C "$DEMO" symbolic-ref HEAD refs/heads/feature/race-car 2>/dev/null )
fi
touch "$DEMO/draft.txt"
W=$(tput cols 2>/dev/null); case "$W" in ''|*[!0-9]*) W=118 ;; esac
R5=$(( $(date +%s) + 12600 ))
LABEL_W=12   # all label prefixes below are exactly 12 chars
J='{"model":{"display_name":"Opus 4.8 (1M context)"},"effort":{"level":"high"},"context_window":{"used_percentage":30},"rate_limits":{"five_hour":{"resets_at":'"$R5"'}},"cwd":"'"$DEMO"'","terminal":{"width":'"$(( W - LABEL_W ))"'}}'
run() { printf '%s' "$J" | env "$@" bash "$SL"; printf '\n'; }

echo "── themes (flame caps) ──"
printf '  danny     '; run STATUSLINE_THEME=danny     STATUSLINE_CAP_GAP=1
printf '  dark-dan  '; run STATUSLINE_THEME=dark-dan  STATUSLINE_CAP_GAP=1
echo
echo "── cap styles (danny) ──"
for c in flame slant rounded pointed; do
  printf '  %-8s  ' "$c"
  [ "$c" = flame ] && run STATUSLINE_CAPS="$c" STATUSLINE_CAP_GAP=1 || run STATUSLINE_CAPS="$c"
done
