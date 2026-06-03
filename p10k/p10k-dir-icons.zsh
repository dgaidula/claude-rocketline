# p10k-dir-icons.zsh — location-based directory icon + capped-parent dir segment.
#
# Drop-in companion to the claude-code-statusline project: it teaches the p10k
# prompt the same icon language the status line uses, so your shell prompt and
# Claude Code agree on "where am I" — and it caps the long parent directory so a
# deep path stays short on small / split panes.
#
#   exact $HOME            → house ()
#   ~/Resilio Sync/**      → sync  ()
#   everywhere else        → folder ()
#   non-writable / root    → lock  ()   (needs sudo)
#
# It replaces p10k's built-in `dir` segment with `cappeddir`, which shows the last
# N path segments and truncates the FIRST shown one (the parent) to a max length:
#
#   FVD-20-1111 Chef Ann Updates/chefann-craft-cms-ddev
#         →  FVD-20-1111 Chef…/chefann-craft-cms-ddev
#
# Install: source this AFTER ~/.p10k.zsh in your ~/.zshrc, e.g.
#   [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
#   [[ ! -f ~/.config/p10k/p10k-dir-icons.zsh ]] || source ~/.config/p10k/p10k-dir-icons.zsh
# Sourcing afterward overrides the matching globals + swaps the dir segment, so it
# survives `p10k configure` regenerating ~/.p10k.zsh. (Needs a Nerd Font.)
#
# Tunables (set before sourcing, or edit here):
#   POWERLEVEL9K_DIR_PARENT_MAX_LEN  parent cap in chars (default 16: "FVD-20-1111 Chef" + …)
#   POWERLEVEL9K_SHORTEN_DIR_LENGTH  how many trailing segments to show (default 2)
#   POWERLEVEL9K_DIR_SYNC_ROOT       the "sync" tree (default ~/Resilio Sync; no-op if absent)
#   _P9K_DIR_ICON_{HOME,SYNC,FOLDER,LOCK}  override individual glyphs
# Colors follow p10k's POWERLEVEL9K_DIR_{,ANCHOR_,SHORTENED_}FOREGROUND / BACKGROUND.

typeset -g POWERLEVEL9K_DIR_PARENT_MAX_LEN=${POWERLEVEL9K_DIR_PARENT_MAX_LEN:-16}
typeset -g POWERLEVEL9K_SHORTEN_DIR_LENGTH=${POWERLEVEL9K_SHORTEN_DIR_LENGTH:-2}
typeset -g POWERLEVEL9K_DIR_SYNC_ROOT=${POWERLEVEL9K_DIR_SYNC_ROOT:-$HOME/Resilio Sync}

typeset -g _P9K_DIR_ICON_HOME=${_P9K_DIR_ICON_HOME:-$''}     # house  (F015)
typeset -g _P9K_DIR_ICON_SYNC=${_P9K_DIR_ICON_SYNC:-$''}     # sync   (F021)
typeset -g _P9K_DIR_ICON_FOLDER=${_P9K_DIR_ICON_FOLDER:-$''} # folder (F07B)
typeset -g _P9K_DIR_ICON_LOCK=${_P9K_DIR_ICON_LOCK:-$''}     # lock   (F023)

# Capped-parent dir segment: last N segments, first shown one truncated to max len.
function prompt_cappeddir() {
  emulate -L zsh
  local home=$HOME pwd=$PWD
  local -i maxlen=$POWERLEVEL9K_DIR_PARENT_MAX_LEN
  local -i depth=$POWERLEVEL9K_SHORTEN_DIR_LENGTH
  (( depth > 0 )) || depth=2

  # ~ abbreviation, then split into path segments (empties dropped by zsh).
  local disp=$pwd
  if [[ $pwd == $home ]]; then disp='~'
  elif [[ $pwd == $home/* ]]; then disp='~/'${pwd#$home/}; fi
  local -a parts=( ${(s:/:)disp} )
  (( $#parts > depth )) && parts=( ${parts[-depth,-1]} )

  # Colors — match p10k Rainbow's dir (override via the POWERLEVEL9K_DIR_* params).
  local fg=${POWERLEVEL9K_DIR_FOREGROUND:-254}
  local afg=${POWERLEVEL9K_DIR_ANCHOR_FOREGROUND:-255}
  local sfg=${POWERLEVEL9K_DIR_SHORTENED_FOREGROUND:-250}
  local bg=${POWERLEVEL9K_DIR_BACKGROUND:-4}
  local b='' nb=''
  [[ ${POWERLEVEL9K_DIR_ANCHOR_BOLD:-true} == true ]] && { b='%B'; nb='%b' }

  local text='' seg cut
  local -i i n=$#parts
  for (( i = 1; i <= n; ++i )); do
    seg=$parts[i]
    if (( i == 1 && n > 1 && $#seg > maxlen )); then     # cap the parent
      cut=${seg[1,maxlen]}
      text+="${b}%F{$afg}${cut//\%/%%}${nb}%F{$sfg}…"
    else                                                  # anchor (bold)
      text+="${b}%F{$afg}${seg//\%/%%}${nb}"
    fi
    (( i < n )) && text+="%F{$fg}/"
  done

  # Location icon; lock wins if the directory isn't writable.
  local icon=$_P9K_DIR_ICON_FOLDER
  if [[ $pwd == $home ]]; then icon=$_P9K_DIR_ICON_HOME
  elif [[ $pwd == $POWERLEVEL9K_DIR_SYNC_ROOT || $pwd == $POWERLEVEL9K_DIR_SYNC_ROOT/* ]]; then
    icon=$_P9K_DIR_ICON_SYNC
  fi
  [[ -w $pwd ]] || icon=$_P9K_DIR_ICON_LOCK

  p10k segment -b "$bg" -f "$fg" -i "$icon" -t "$text"
}
# Fast path for p10k's instant prompt (sync, no subprocess) so the first line matches.
function instant_prompt_cappeddir() { prompt_cappeddir }

# Swap p10k's built-in `dir` for `cappeddir` in whichever prompt side hosts it.
() {
  emulate -L zsh -o extended_glob
  local side var
  for side in LEFT RIGHT; do
    var=POWERLEVEL9K_${side}_PROMPT_ELEMENTS
    (( $+parameters[$var] )) || continue
    set -A $var "${(@)${(P)var}/(#s)dir(#e)/cappeddir}"
  done
}
