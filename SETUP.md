# Portable setup

Get the **Claude Code status line** and the **matching Powerlevel10k prompt icons**
running on a new machine (macOS or AlmaLinux / RHEL-family). Both pieces share one
icon language — house / sync / folder / lock by location — so your shell prompt and
Claude Code always agree on *where you are*.

```
 home ()      → you are in $HOME
 sync ()      → you are under ~/Resilio Sync
 folder ()    → anywhere else
 lock ()      → directory isn't writable (root-owned, needs sudo)
```

---

## 1. Prerequisites

| Need | Why | macOS | AlmaLinux / RHEL |
|---|---|---|---|
| **Nerd Font** (client-side) | renders the glyphs | `brew install --cask font-meslo-lg-nerd-font` | install on your **local** terminal, not the server (see note) |
| `jq` | status line parses Claude's JSON | `brew install jq` | `sudo dnf install -y jq` |
| `git` | status line repo/branch segment | preinstalled (Xcode CLT) | `sudo dnf install -y git` |
| `perl` | status line width math (`-CSD`) | preinstalled | preinstalled (`perl-core`) |
| `zsh` + **Powerlevel10k** | the prompt icons (optional — only for the p10k piece) | `brew install powerlevel10k` | see below |

> **Nerd Font is a client-side thing.** Glyphs are drawn by the terminal you're *looking
> at*. When you SSH into the Linode, install the Nerd Font on the **Mac** running the
> terminal — nothing font-related needs to exist on the server. The status line's OS icon
> auto-switches to the Linux glyph () on the server on its own.

**Powerlevel10k on AlmaLinux** (not packaged in the default repos):

```sh
sudo dnf install -y zsh
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' >> ~/.zshrc
# optional: make zsh your login shell
chsh -s "$(command -v zsh)"
```

Run `p10k configure` once (pick the **Rainbow** style) to generate `~/.p10k.zsh`.

---

## 2. Install the status line

```sh
git clone https://github.com/<you>/claude-code-statusline.git
cd claude-code-statusline
./install.sh        # copies statusline.sh → ~/.claude/ and prints the settings snippet
```

Then add to `~/.claude/settings.json` (merge with any existing config):

```json
{
  "statusLine": { "type": "command", "command": "~/.claude/statusline.sh" }
}
```

Dark theme + rounded caps instead:

```json
"command": "STATUSLINE_THEME=dark-dan STATUSLINE_CAPS=rounded ~/.claude/statusline.sh"
```

---

## 3. Install the matching p10k prompt icons (optional)

The drop-in `p10k/p10k-dir-icons.zsh` sets the location classes/icons. Source it **after**
`~/.p10k.zsh` so it overrides the generated config and **survives `p10k configure` re-runs**:

```sh
mkdir -p ~/.config/p10k
cp p10k/p10k-dir-icons.zsh ~/.config/p10k/

# add to ~/.zshrc, right after the line that sources ~/.p10k.zsh:
cat >> ~/.zshrc <<'EOF'
[[ ! -f ~/.config/p10k/p10k-dir-icons.zsh ]] || source ~/.config/p10k/p10k-dir-icons.zsh
EOF

exec zsh   # reload
```

`~/.zshrc` order matters — the source line must come **after** `source ~/.p10k.zsh`.

---

## 4. Verify

- **Status line:** open a Claude Code session — you should see a location icon before the
  repo name (sync/folder/lock as appropriate).
- **Prompt:** `cd ~` → house; `cd` into `~/Resilio Sync/...` → sync; anywhere else → folder;
  `cd /usr` (or any root-owned dir) → lock.

After `exec zsh`, the **first** prompt line may be a stale snapshot (p10k's instant-prompt
cache); it corrects on the next command. To force-clear it: `rm -f ~/.cache/p10k-instant-prompt-*.zsh`.

---

## 5. Per-host tweaks

- **No `~/Resilio Sync` on a host** (e.g. the Linode)? The sync rule is a harmless no-op
  there and you simply get folders. To repurpose it for a different tree, edit the first
  pattern in `p10k-dir-icons.zsh` (and the status line's `case "$cwd"` block) — both use the
  same `~/Resilio Sync` convention.
- **Whole home tree as a house** (not just `$HOME` itself): change the `'~'` pattern to
  `'~(|/*)'` in `p10k-dir-icons.zsh`.
- **Path depth:** `POWERLEVEL9K_SHORTEN_DIR_LENGTH` in the drop-in (2 = parent/dir, 3 adds
  the grandparent).

> The status line's location logic lives in the `case "$cwd"` block near the RIGHT section of
> `statusline.sh`; the p10k logic lives in `p10k-dir-icons.zsh`. Keep the two `~/Resilio Sync`
> patterns in sync if you change one.

---

## 6. cmux notifications (optional, macOS only)

[cmux](https://cmux.com) is a macOS terminal built on libghostty (reads your existing
`~/.config/ghostty/config`) with a per-workspace sidebar — it lights up a tab / rings a pane
when an agent there is waiting. These Claude Code hooks drive that indicator. **macOS 14+,
Apple Silicon or Intel.** Skip this section on the Minis if you stay on Ghostty, and on Linux.

### Install cmux

```sh
brew tap manaflow-ai/cmux
brew install --cask cmux
# update later: brew upgrade --cask cmux
```

(Or download the DMG from the [latest release](https://github.com/manaflow-ai/cmux/releases/latest)
and drag to Applications — that path auto-updates via Sparkle.)

### Put the `cmux` CLI on PATH (required for the hooks)

The hooks call `cmux notify`, so the CLI must be resolvable — otherwise they silently no-op:

```sh
sudo ln -sf "/Applications/cmux.app/Contents/Resources/bin/cmux" /usr/local/bin/cmux
cmux notify --title "test" --body "hello"   # should pop a notification
```

### Wire the hooks (`~/.claude/settings.json`)

Merge this `hooks` block into your existing settings (don't clobber other keys). Both hooks
are **guarded** (`command -v cmux || exit 0`) so they're a clean no-op on any machine without
cmux, and **async** so they never add latency to a turn:

```json
{
  "hooks": {
    "Notification": [
      { "hooks": [ {
        "type": "command",
        "command": "command -v cmux >/dev/null 2>&1 || exit 0; msg=$(jq -r '.message // empty' 2>/dev/null); cmux notify --title \"Claude Code\" --body \"${msg:-Waiting for you}\"",
        "async": true
      } ] }
    ],
    "Stop": [
      { "hooks": [ {
        "type": "command",
        "command": "command -v cmux >/dev/null 2>&1 || exit 0; dir=$(jq -r '.cwd // empty' 2>/dev/null); cmux notify --title \"Claude Code — done\" --body \"${dir##*/}\"",
        "async": true
      } ] }
    ]
  }
}
```

- **`Notification`** fires when Claude needs you (permission / waiting on input); body = Claude's
  own notification text.
- **`Stop`** fires when a turn finishes; body = the repo folder name (so a backgrounded
  workspace's tab tells you *which* repo is done). It fires **every** turn — if that's noisy in
  the focused pane, disable just this one via the `/hooks` menu and keep `Notification`.

After editing settings, open **`/hooks`** once (or restart Claude Code) so the hook config
reloads.
