#!/usr/bin/env bash
# Installer for claude-code-statusline.
# Copies statusline.sh into ~/.claude/ and prints the settings.json snippet to add.
set -e

SRC="$(cd "$(dirname "$0")" && pwd)/statusline.sh"
DEST_DIR="$HOME/.claude"
DEST="$DEST_DIR/statusline.sh"

mkdir -p "$DEST_DIR"
cp "$SRC" "$DEST"
chmod +x "$DEST"
echo "✅ Installed: $DEST"

# Friendly dependency checks (non-fatal).
for cmd in jq git; do
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

⚠️  Requires a Nerd Font (e.g. MesloLGS NF) for the glyphs to render.
EOF
