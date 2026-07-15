#!/usr/bin/env bash
# Render the responsive layout at several terminal widths — for a README screenshot.
# Widen your terminal to ~115+ cols, run this, and screenshot the output.
# Usage:  bash demos/responsive.sh
SL="${STATUSLINE_SH:-$(cd "$(dirname "$0")/.." && pwd)/statusline.sh}"

DEMO="/tmp/ccsl-demo/my-app"
if [ ! -e "$DEMO/.git" ]; then
  mkdir -p "$DEMO"
  ( unset GIT_DIR GIT_WORK_TREE
    git init -q "$DEMO" 2>/dev/null
    git -C "$DEMO" symbolic-ref HEAD refs/heads/feature/race-car 2>/dev/null )
fi
touch "$DEMO/draft.txt"
R5=$(( $(date +%s) + 12600 ))   # ~3h30m, so the reset countdown shows
export STATUSLINE_CAP_GAP=1     # matches live settings — flame looks flush without it

at_width() {  # $1 = columns
  printf '{"model":{"display_name":"Opus 4.8 (1M context)"},"effort":{"level":"high"},"context_window":{"used_percentage":30},"rate_limits":{"five_hour":{"resets_at":%s}},"cwd":"%s","terminal":{"width":%s}}' \
    "$R5" "$DEMO" "$1" | bash "$SL"
}

printf '\nResponsive layout — the bar sheds segments to fit the terminal width.\n'
printf 'Peel order: clock -> branch -> repo -> reset -> [effort] -> (model qualifier) -> context.\n\n'
for W in 115 90 70 55 42 32; do
  printf '%3s cols\n' "$W"
  at_width "$W"
  printf '\n\n'
done
