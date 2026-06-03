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

## 3. Install the matching p10k prompt dir segment (optional)

The drop-in `p10k/p10k-dir-icons.zsh` replaces p10k's built-in `dir` segment with `cappeddir`,
which shows the last N path segments, **caps the parent to a max length**, and carries the same
house/sync/folder/lock icons:

```
FVD-20-1111 Chef Ann Updates/chefann-craft-cms-ddev   →    FVD-20-1111 Chef…/chefann-craft-cms-ddev
```

Source it **after** `~/.p10k.zsh` so it overrides the generated config and **survives
`p10k configure` re-runs**:

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
  there and you simply get folders. To repurpose it for a different tree, set
  `POWERLEVEL9K_DIR_SYNC_ROOT` in `p10k-dir-icons.zsh` (and the status line's `case "$cwd"`
  block uses the same `~/Resilio Sync` convention).
- **Parent cap length:** `POWERLEVEL9K_DIR_PARENT_MAX_LEN` in the drop-in (default 16 →
  `FVD-20-1111 Chef…`). Set high (e.g. 99) to effectively disable capping.
- **Path depth:** `POWERLEVEL9K_SHORTEN_DIR_LENGTH` in the drop-in (2 = parent/repo, 3 adds
  the grandparent). Only the first shown segment is capped; only the last (repo) is bold.
- **Narrow panes:** `POWERLEVEL9K_DIR_NARROW_COLS` (default 80) — when `$COLUMNS` is below this
  (e.g. a tight cmux split), depth collapses to **1** (repo only, parent dropped). Set `0` to
  disable the responsive collapse.
- **Sync tree:** `POWERLEVEL9K_DIR_SYNC_ROOT` (default `~/Resilio Sync`) picks which tree gets
  the sync icon; harmless no-op on hosts without it.
- **Icons / colors:** `_P9K_DIR_ICON_{HOME,SYNC,FOLDER,LOCK}` override glyphs; the segment
  reuses p10k's `POWERLEVEL9K_DIR_{,ANCHOR_,SHORTENED_}FOREGROUND` / `BACKGROUND` for colors.

> The status line's location logic lives in the `case "$cwd"` block near the RIGHT section of
> `statusline.sh`; the p10k logic lives in `p10k-dir-icons.zsh`. Keep the two `~/Resilio Sync`
> patterns in sync if you change one.

---

## 6. cmux notifications (optional, macOS only)

[cmux](https://cmux.com) is a macOS terminal built on libghostty (reads your existing
`~/.config/ghostty/config`) with a per-workspace sidebar — it lights up a tab / rings a pane
when an agent there is waiting. **macOS 14+, Apple Silicon or Intel.** Skip on the Minis if you
stay on Ghostty, and on Linux.

### Install cmux

```sh
brew tap manaflow-ai/cmux
brew install --cask cmux
# update later: brew upgrade --cask cmux
```

(Or download the DMG from the [latest release](https://github.com/manaflow-ai/cmux/releases/latest)
and drag to Applications — that path auto-updates via Sparkle.)

Optional: put the CLI on PATH for `cmux` workspace commands from a pane:

```sh
sudo ln -sf "/Applications/cmux.app/Contents/Resources/bin/cmux" /usr/local/bin/cmux
```

### Claude Code: nothing to wire — it's automatic

**Do NOT add `cmux notify` hooks to `~/.claude/settings.json`.** cmux special-cases Claude
Code: per `cmux hooks --help`, *"Claude Code hooks are injected automatically by the cmux Claude
wrapper."* Just **launch `claude` inside a cmux pane** and the waiting/done indicators light up
on their own — no install command, no settings edit. (Other agents like codex/opencode/gemini
*do* need `cmux hooks setup`; Claude doesn't.)

A manual `cmux notify` hook is actively wrong here: it would **double-fire** inside cmux, and
**error** (`Failed to write to socket (Broken pipe)`) anywhere else — because `cmux notify` only
resolves a target when run *inside* a cmux pane (it reads `CMUX_*` session env vars). That same
reason is why a standalone `cmux notify --title test` from Ghostty/Terminal fails; it's expected,
not a bug.

### Verify

Open cmux → open a workspace on a repo → run `claude` in that pane → trigger a permission prompt
or let a turn finish. The pane should ring / the sidebar tab should light. If you'd previously
added manual `cmux notify` hooks, remove them (`/hooks` menu) so they don't double up.
