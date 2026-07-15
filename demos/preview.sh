#!/usr/bin/env bash
# Preview the status line across scenarios, in real color.
# Usage:  bash demos/preview.sh
SL="${STATUSLINE_SH:-$(cd "$(dirname "$0")/.." && pwd)/statusline.sh}"

# Throwaway fake repo so repo+branch always render.
DEMO="/tmp/ccsl-demo/my-app"
if [ ! -e "$DEMO/.git" ]; then
  mkdir -p "$DEMO"
  ( unset GIT_DIR GIT_WORK_TREE
    git init -q "$DEMO" 2>/dev/null
    git -C "$DEMO" symbolic-ref HEAD refs/heads/feature/race-car 2>/dev/null )
fi
W=$(tput cols 2>/dev/null); case "$W" in ''|*[!0-9]*) W=118 ;; esac
R5=$(( $(date +%s) + 12600 ))   # ~3h30m
export STATUSLINE_CAP_GAP=1     # matches live settings — flame looks flush without it

LABEL_W=29   # '  %-26s ' = 2 + 26 + 1

scene() { # $1 label  $2 used%  $3 dirty(1/0)  $4 extra-env...
  local label=$1 used=$2 dirty=$3; shift 3
  if [ "$dirty" = 1 ]; then touch "$DEMO/draft.txt"; else rm -f "$DEMO/draft.txt"; fi
  printf '  %-26s ' "$label"
  printf '{"model":{"display_name":"Opus 4.8 (1M context)"},"effort":{"level":"high"},"context_window":{"used_percentage":%s},"rate_limits":{"five_hour":{"resets_at":%s}},"cwd":"%s","terminal":{"width":%s}}' \
    "$used" "$R5" "$DEMO" "$(( W - LABEL_W ))" | env "$@" bash "$SL"
  printf '\n'
}

echo "── scenarios (danny) ──"
scene "low ctx, clean"   18 0
scene "mid ctx, dirty"   68 1
scene "high ctx, dirty"  91 1
echo
echo "── dark-dan ──"
scene "dark-dan, dirty"  40 1 STATUSLINE_THEME=dark-dan
