# p10k-dir-icons.zsh — location-based directory icon for Powerlevel10k.
#
# Drop-in companion to the claude-code-statusline project: it teaches the p10k
# prompt the same icon language the status line uses, so your shell prompt and
# Claude Code agree on "where am I".
#
#   exact $HOME            → house ()   POWERLEVEL9K_DIR_CLASSES: HOME
#   ~/Resilio Sync/**      → sync  ()   POWERLEVEL9K_DIR_CLASSES: SYNC
#   everywhere else        → folder ()   POWERLEVEL9K_DIR_CLASSES: DEFAULT
#   non-writable / root    → lock  ()   via SHOW_WRITABLE=v3 (_NOT_WRITABLE class)
#
# Install: source this AFTER ~/.p10k.zsh in your ~/.zshrc, e.g.
#   [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
#   [[ ! -f ~/.config/p10k/p10k-dir-icons.zsh ]] || source ~/.config/p10k/p10k-dir-icons.zsh
# Sourcing afterward overrides the matching globals, so it survives `p10k configure`
# regenerating ~/.p10k.zsh. (Requires a Nerd Font in your terminal for the glyphs.)
#
# Tweak points:
#   • Show the WHOLE home tree as a house: change the '~' pattern to '~(|/*)'.
#   • Different "special" tree instead of Resilio Sync: edit the first pattern
#     (e.g. '~/code(|/*)') and rename SYNC → whatever, updating the *_VISUAL_
#     IDENTIFIER_EXPANSION line to match. On a host without that tree the rule is
#     simply a harmless no-op and you get folders.
#   • Trailing path depth: POWERLEVEL9K_SHORTEN_DIR_LENGTH (segments kept).

# Show the last N path segments (truncate the rest). 2 = parent/dir; 3 = grandparent/parent/dir.
typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_to_last
typeset -g POWERLEVEL9K_SHORTEN_DIR_LENGTH=2

# Swap the class icon for a lock on non-writable / non-existent dirs (e.g. root-owned).
typeset -g POWERLEVEL9K_DIR_SHOW_WRITABLE=v3

# Location → class. First matching pattern wins, so the Resilio rule must precede
# the bare-home rule (Resilio Sync also lives under ~).
typeset -g POWERLEVEL9K_DIR_CLASSES=(
  '~/Resilio Sync(|/*)'  SYNC     ''
  '~'                    HOME     ''
  '*'                    DEFAULT  '')

# Per-class icons (Nerd Font code points).
typeset -g POWERLEVEL9K_DIR_HOME_VISUAL_IDENTIFIER_EXPANSION=$''     # house
typeset -g POWERLEVEL9K_DIR_SYNC_VISUAL_IDENTIFIER_EXPANSION=$''     # sync (circular arrows)
typeset -g POWERLEVEL9K_DIR_DEFAULT_VISUAL_IDENTIFIER_EXPANSION=$''  # folder
