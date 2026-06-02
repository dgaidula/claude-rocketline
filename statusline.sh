#!/usr/bin/env bash
# claude-code-statusline — statusline.sh
# Compact, themeable Claude Code status line in p10k "Rainbow" angled style.
#   LEFT  — <os> 🤖 (apple+AI) · model (dark blue) · context % | reset (compact bar)
#   RIGHT — repo name (no root path) ·  branch · clock   (right-aligned)
#
# Customize via env (set in settings.json → statusLine.command):
#   STATUSLINE_THEME = danny | dark-dan            (default danny)
#   STATUSLINE_CAPS  = flame | slant | rounded | pointed   (default flame)
#   STATUSLINE_OS_ICON = <glyph>                   (default: auto by OS)
#   STATUSLINE_CTX_ICON, STATUSLINE_PIPE, STATUSLINE_LCAP, STATUSLINE_RCAP  (fine overrides)
# Requires a Nerd Font (e.g. MesloLGS NF). Efficient: stdin read once; jq once per field.

[ -z "$LC_ALL" ] && export LC_ALL=en_US.UTF-8

# Some shells export GIT_DIR=./.git, which breaks `git -C <subdir>`. Neutralize it.
unset GIT_DIR GIT_WORK_TREE

input=$(cat)
jqr() { printf '%s' "$input" | jq -r "$1 // empty" 2>/dev/null; }

e=$(printf '\033')
RESET="${e}[0m"

# ── glyphs (generated from codepoints so raw PUA bytes survive editing) ───────
SEP=$(printf '\xee\x82\xb0')      # E0B0  internal left-prompt separator (►)
SUBSEP=$(printf '\xee\x82\xb1')   # E0B1  thin separator (same-color neighbors)
RSEP=$(printf '\xee\x82\xb2')     # E0B2  internal right-prompt separator (◄)
BR=$(printf '\xef\x84\xa6')       # F126  VCS branch icon
CLOCK=$(printf '\xef\x80\x97')    # F017  clock
CTX_ICON=${STATUSLINE_CTX_ICON:-$(printf '\xf0\x9f\xa7\xa0')}   # 🧠 brain
# cap glyphs
PL_RT=$(printf '\xee\x82\xb0')    # E0B0  pointed ►
PL_LT=$(printf '\xee\x82\xb2')    # E0B2  pointed ◄
RND_RT=$(printf '\xee\x82\xb4')   # E0B4  rounded )
RND_LT=$(printf '\xee\x82\xb6')   # E0B6  rounded (
SLN_FW=$(printf '\xee\x82\xbc')   # E0BC  slant "/" (right edge)
SLN_BW=$(printf '\xee\x82\xba')   # E0BA  slant "/" (left edge)
FLAME_L=$(printf '\xee\x83\x82')  # E0C2  flame (points out, left)

# ── OS icon (auto) ────────────────────────────────────────────────────────────
case "$(uname -s)" in
  Darwin) OS_ICON=$(printf '\xef\x85\xb9') ;;   # F179 apple
  Linux)  OS_ICON=$(printf '\xef\x85\xbc') ;;   # F17C linux
  *)      OS_ICON=$(printf '\xef\x85\xba') ;;   # F17A windows
esac
OS_ICON=${STATUSLINE_OS_ICON:-$OS_ICON}

# ── theme palette ─────────────────────────────────────────────────────────────
case "${STATUSLINE_THEME:-danny}" in
  dark-dan)   # true dark: dim neutrals, flame is the one bright accent
    NEUTRAL=${STATUSLINE_NEUTRAL:-238}        # badge + clock grey
    NFG=${STATUSLINE_NEUTRAL_FG:-250}         # text on the grey segments
    BLUE=${STATUSLINE_BLUE:-24}               # model + repo teal-blue
    BADGE_BG=${STATUSLINE_BADGE_BG:-$NEUTRAL}; BADGE_FG=${STATUSLINE_BADGE_FG:-$NFG}
    MODEL_BG=$BLUE;  MODEL_FG=252
    CTX_FG=252;   CTX_GREEN=28; CTX_YELLOW=136; CTX_RED=124
    REPO_BG=$BLUE;   REPO_FG=252
    BRANCH_FG=252; BRANCH_CLEAN=28; BRANCH_DIRTY=136
    TIME_BG=${STATUSLINE_TIME_BG:-$NEUTRAL};  TIME_FG=${STATUSLINE_TIME_FG:-$NFG}
    PIPE_COLOR=240; FLAME_COLOR=208
    ;;
  *)          # danny (default) — light badge leading, 238-grey clock anchoring the right
    BADGE_BG=${STATUSLINE_BADGE_BG:-${STATUSLINE_NEUTRAL:-7}};    BADGE_FG=${STATUSLINE_BADGE_FG:-232}
    MODEL_BG=${STATUSLINE_BLUE:-24};  MODEL_FG=254
    CTX_FG=254;   CTX_GREEN=2; CTX_YELLOW=3; CTX_RED=1
    REPO_BG=4;    REPO_FG=254
    BRANCH_FG=0;  BRANCH_CLEAN=2; BRANCH_DIRTY=3
    TIME_BG=${STATUSLINE_TIME_BG:-${STATUSLINE_NEUTRAL:-238}};  TIME_FG=${STATUSLINE_TIME_FG:-250}
    PIPE_COLOR=250; FLAME_COLOR=208
    ;;
esac
PIPE_COLOR=${STATUSLINE_PIPE:-$PIPE_COLOR}
PIPE="${e}[38;5;${PIPE_COLOR}m"

# ── end caps (outer ends + the two caps facing the center gap) ────────────────
case "${STATUSLINE_CAPS:-flame}" in
  slant)    OUTER_L=$SLN_BW;                              OUTER_R=$SLN_FW; GAP_L=$SLN_FW; GAP_R=$SLN_BW ;;
  rounded)  OUTER_L=$RND_LT;                              OUTER_R=$RND_RT; GAP_L=$RND_RT; GAP_R=$RND_LT ;;
  pointed)  OUTER_L=$PL_LT;                               OUTER_R=$PL_RT;  GAP_L=$PL_RT;  GAP_R=$PL_LT ;;
  *)        OUTER_L="${e}[38;5;${FLAME_COLOR}m${FLAME_L}"; OUTER_R=$SLN_FW; GAP_L=$SLN_FW; GAP_R=$SLN_BW ;;  # flame
esac
OUTER_L=${STATUSLINE_LCAP:-$OUTER_L}
OUTER_R=${STATUSLINE_RCAP:-$OUTER_R}

# ── renderers ─────────────────────────────────────────────────────────────────
# Left chain: "bg|fg|text" ... — angled OUTER_L cap, slant trailing cap into gap.
render_lchain() {
  local prev_bg="" out="" seg bg rest fg txt first_bg=""
  for seg in "$@"; do
    bg="${seg%%|*}"; rest="${seg#*|}"; fg="${rest%%|*}"; txt="${rest#*|}"
    if [ -z "$out" ]; then first_bg="$bg"
    elif [ "$prev_bg" = "$bg" ]; then
      out="${out}${e}[48;5;${bg}m${e}[38;5;0m${SUBSEP}"
    else
      out="${out}${e}[48;5;${bg}m${e}[38;5;${prev_bg}m${SEP}"
    fi
    out="${out}${e}[48;5;${bg}m${e}[38;5;${fg}m ${txt} "
    prev_bg="$bg"
  done
  if [ -n "$out" ]; then
    out="${e}[49m${e}[38;5;${first_bg}m${OUTER_L}${out}${RESET}${e}[38;5;${prev_bg}m${GAP_L}${RESET}"
  fi
  printf '%s' "$out"
}

# Right chain: "bg|fg|text" ... — slant gap cap, angled OUTER_R end.
render_rchain() {
  local prev_bg="" out="" seg bg rest fg txt
  for seg in "$@"; do
    bg="${seg%%|*}"; rest="${seg#*|}"; fg="${rest%%|*}"; txt="${rest#*|}"
    if [ -z "$out" ]; then
      out="${e}[49m${e}[38;5;${bg}m${GAP_R}"
    else
      out="${out}${e}[48;5;${prev_bg}m${e}[38;5;${bg}m${RSEP}"
    fi
    out="${out}${e}[48;5;${bg}m${e}[38;5;${fg}m ${txt} "
    prev_bg="$bg"
  done
  [ -n "$out" ] && out="${out}${e}[49m${e}[38;5;${prev_bg}m${OUTER_R}${RESET}"
  printf '%s' "$out"
}

# Visible width: strip ANSI, count chars, +1 per double-wide emoji.
visw() {
  local clean chars wide
  clean=$(printf '%s' "$1" | sed "s/${e}\[[0-9;]*m//g")
  chars=$(printf '%s' "$clean" | wc -m | tr -d ' ')
  wide=$(printf '%s' "$clean" | grep -o $'🤖\|🧠\|⏱\|🌿\|✅\|🔄\|📝\|🔀' | wc -l | tr -d ' ')
  printf '%s' $(( chars + wide ))
}

# ── LEFT pieces: <os> 🤖 · model · context (built at variable detail for narrow widths)
model=$(jqr '.model.display_name')
effort=$(jqr '.effort.level')
model_full="${model//context/ctx}"; [ -n "$effort" ] && model_full="${model_full}[${effort}]"
model_noeff="${model//context/ctx}"     # drop [effort]
model_short="${model%% (*}"             # drop the "(1M ctx)" qualifier → "Opus 4.8"

# Compact 5h-limit reset countdown, like "🧠 68%|2h13m".
reset_str=""
five_resets=$(jqr '.rate_limits.five_hour.resets_at')
if [ -n "$five_resets" ]; then
  now=$(date +%s); secs=$(( five_resets - now ))
  if [ "$secs" -gt 0 ]; then
    h=$(( secs / 3600 )); m=$(( (secs % 3600) / 60 ))
    if [ "$h" -gt 0 ]; then dur="${h}h${m}m"; else dur="${m}m"; fi
    reset_str="${PIPE}|${e}[38;5;${CTX_FG}m${dur}"
  fi
fi

has_ctx=""; cbg=""; remaining=""
used_pct=$(jqr '.context_window.used_percentage')
if [ -n "$used_pct" ]; then
  has_ctx=1; used_int=$(printf '%.0f' "$used_pct"); remaining=$((100 - used_int))
  if [ "$used_int" -ge 85 ]; then cbg=$CTX_RED
  elif [ "$used_int" -ge 60 ]; then cbg=$CTX_YELLOW
  else cbg=$CTX_GREEN; fi
fi

# Render the left chain at a detail level (0=full … 4=minimal). As width tightens
# we trim, in order: reset countdown → [effort] → "(1M ctx)" qualifier → context chip.
build_left() {
  local lvl=$1 mtxt ctxt; local ll=()
  case "$lvl" in
    0|1) mtxt="$model_full" ;;
    2)   mtxt="$model_noeff" ;;
    *)   mtxt="$model_short" ;;
  esac
  ll=("${BADGE_BG}|${BADGE_FG}|${OS_ICON} 🤖" "${MODEL_BG}|${MODEL_FG}|${mtxt}")
  if [ -n "$has_ctx" ]; then
    case "$lvl" in
      0)     ctxt="${CTX_ICON} ${remaining}%${reset_str}" ;;  # full
      1|2|3) ctxt="${CTX_ICON} ${remaining}%" ;;              # drop reset countdown
      *)     ctxt="" ;;                                       # drop context chip
    esac
    [ -n "$ctxt" ] && ll+=("${cbg}|${CTX_FG}|${ctxt}")
  fi
  render_lchain "${ll[@]}"
}

# ── RIGHT: repo (no root path) · branch · clock ──────────────────────────────
cwd=$(jqr '.cwd')
r=()
if [ -n "$cwd" ] && command -v git >/dev/null 2>&1; then
  gitroot=$(git -C "$cwd" --no-optional-locks rev-parse --show-toplevel 2>/dev/null)
  if [ -n "$gitroot" ]; then
    # repo name + in-repo subpath, via git's own relative path (robust to symlinks
    # like macOS /tmp → /private/tmp, where a plain prefix-strip would fail).
    prefix=$(git -C "$cwd" --no-optional-locks rev-parse --show-prefix 2>/dev/null)
    prefix=${prefix%/}
    repo_disp="${gitroot##*/}${prefix:+/$prefix}"
    r+=("${REPO_BG}|${REPO_FG}|${repo_disp}")
    branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
    if [ -n "$branch" ]; then
      dirty=$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null | head -1)
      if [ -n "$dirty" ]; then vbg=$BRANCH_DIRTY; else vbg=$BRANCH_CLEAN; fi
      r+=("${vbg}|${BRANCH_FG}|${BR} ${branch}")
    fi
  fi
fi
r+=("${TIME_BG}|${TIME_FG}|${CLOCK} $(date '+%H:%M:%S')")

# ── terminal width ────────────────────────────────────────────────────────────
cols=$(jqr '.terminal.width'); [ -z "$cols" ] && cols=$(jqr '.cols')
[ -z "$cols" ] && cols="$COLUMNS"
[ -z "$cols" ] && cols=$(tput cols 2>/dev/null)
case "$cols" in ''|*[!0-9]*) cols=100 ;; esac
avail=$(( cols - 1 ))            # reserve the last column (avoid edge-wrap)

# ── fit LEFT: keep the least-trimmed left that fits (degrade only when forced) ──
left=""; lw=0
for lvl in 0 1 2 3 4; do
  left=$(build_left "$lvl"); lw=$(visw "$left")
  [ "$lw" -le "$avail" ] && break
done

# ── fit RIGHT: drop segments (clock → branch → repo) until it fits beside left ──
right=""
while [ "${#r[@]}" -gt 0 ]; do
  cand=$(render_rchain "${r[@]}")
  if [ $(( lw + 1 + $(visw "$cand") )) -le "$avail" ]; then
    right="$cand"; break
  fi
  unset "r[$(( ${#r[@]} - 1 ))]"  # drop the rightmost segment
  r=("${r[@]}")                   # reindex
done

# ── emit (right-aligned, padded to avail) ─────────────────────────────────────
if [ -n "$right" ]; then
  pad=$(( avail - lw - $(visw "$right") ))
  [ "$pad" -lt 1 ] && pad=1
  printf '%s%*s%s\n' "$left" "$pad" '' "$right"
else
  printf '%s\n' "$left"
fi
