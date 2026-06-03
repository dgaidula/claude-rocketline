#!/usr/bin/env bash
# Installer for claude-code-statusline.
# Copies statusline.sh into ~/.claude/ and prints the settings.json snippet to add.
# Also stages the optional Powerlevel10k dir-icon drop-in (see SETUP.md).
set -e

HERE="$(cd "$(dirname "$0")" && pwd)"
SRC="$HERE/statusline.sh"
DEST_DIR="$HOME/.claude"
DEST="$DEST_DIR/statusline.sh"

mkdir -p "$DEST_DIR"
cp "$SRC" "$DEST"
chmod +x "$DEST"
echo "✅ Installed: $DEST"

# Optional: stage the p10k dir-icon drop-in (non-invasive — never edits ~/.zshrc).
P10K_SRC="$HERE/p10k/p10k-dir-icons.zsh"
P10K_DEST="$HOME/.config/p10k/p10k-dir-icons.zsh"
if [ -f "$P10K_SRC" ]; then
  mkdir -p "$(dirname "$P10K_DEST")"
  cp "$P10K_SRC" "$P10K_DEST"
  echo "✅ Staged p10k drop-in: $P10K_DEST"
fi

# Friendly dependency checks (non-fatal).
for cmd in jq git perl; do
  command -v "$cmd" >/dev/null 2>&1 || echo "⚠️  '$cmd' not found on PATH — the status line needs it."
done

cat <<'EOF'

Add this to ~/.claude/settings.json (merge with any existing config):

  {
    "statusLine": {
      "type": "command",
      "command": "~/.claude/statusline.sh"
    }
  }

Dark theme + rounded ends:
  "command": "STATUSLINE_THEME=dark-dan STATUSLINE_CAPS=rounded ~/.claude/statusline.sh"

Optional — matching Powerlevel10k prompt icons. Add to ~/.zshrc AFTER the line
that sources ~/.p10k.zsh:

  [[ ! -f ~/.config/p10k/p10k-dir-icons.zsh ]] || source ~/.config/p10k/p10k-dir-icons.zsh

⚠️  Requires a Nerd Font (e.g. MesloLGS NF) for the glyphs to render.
See SETUP.md for full per-OS (macOS / AlmaLinux) instructions.
EOF
