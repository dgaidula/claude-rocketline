# claude-code-statusline

A compact, themeable [Claude Code](https://claude.com/claude-code) status line, styled like a
[Powerlevel10k](https://github.com/romkatv/powerlevel10k) prompt — angled powerline segments, a
context-window meter, git info, and a clock. Built by a designer who cared too much about a
single line in a terminal. 🏎️🔥

![claude-code-statusline — danny theme](docs/hero.png)

<sub>(plain-text fallback if the image hasn't loaded:)</sub>

```
🔥 🤖  Opus 4.8 (1M ctx)[high]  🧠 70%|3h30m  /        / my-app  main  09:00:19  /
```

- **Apple + 🤖 badge** — OS icon (auto: macOS/Linux/Windows) paired with the AI
- **Model** — name + reasoning effort, e.g. `Opus 4.8 (1M ctx)[high]`
- **🧠 Context meter** — % of context window remaining, green→yellow→red, with a recessed
  `| 3h30m` 5-hour-limit reset countdown
- **Repo · branch · clock** — right-aligned; repo shows the folder name (no long root path),
  branch is color-coded clean/dirty
- **Signature "race car" ends** — a flame trailing the left, a slant `/` nosing the right, so the
  line reads like it's moving left→right

## Responsive layout

The bar is width-aware: as the terminal narrows it **sheds the least-important segments instead of
clipping**, then trims the model label — so it always stays on one line. Peel order:

`clock → branch → repo → reset countdown → [effort] → (model qualifier) → context chip`

![responsive layout across terminal widths](docs/responsive.png)

Reproduce it yourself: `bash demos/responsive.sh` (widen to ~115 cols, then screenshot).

## Requirements

- **A [Nerd Font](https://www.nerdfonts.com/)** (e.g. `MesloLGS NF`, the Powerlevel10k default).
  Without one, the powerline separators, flame, apple, branch, and brain glyphs render as tofu (□).
  - You don't have to make a Nerd Font your *primary* terminal font. Any terminal with a
    font-fallback chain (Ghostty, kitty, WezTerm) lets you keep a ligature-rich coding font
    as primary and add a Nerd Font as a **fallback** — the icon codepoints resolve from the
    fallback while your code keeps its ligatures. In Ghostty, just repeat `font-family`:
    ```
    font-family = Your-Coding-Font
    font-family = Symbols Nerd Font Mono
    ```
    Prefer the **symbols-only** build (`brew install --cask font-symbols-only-nerd-font`) so
    the fallback only supplies icons and never lends a stray Latin glyph. No p10k/statusline
    changes are needed — they just emit the codepoints; the terminal renders them.
- `bash`, `jq`, and `git` on `PATH`.
- Claude Code (the status line reads its JSON from stdin).

## Install

```bash
git clone https://github.com/<you>/claude-code-statusline.git
cd claude-code-statusline
./install.sh        # copies statusline.sh to ~/.claude/ and prints the settings snippet
```

Or manually: copy `statusline.sh` to `~/.claude/statusline.sh`, `chmod +x` it, and add this to
`~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

## Themes & options

Set via environment variables in the `command` (they compose):

```json
"command": "STATUSLINE_THEME=dark-dan STATUSLINE_CAPS=rounded ~/.claude/statusline.sh"
```

| Variable | Values | Default | What it does |
|---|---|---|---|
| `STATUSLINE_THEME` | `danny` · `dark-dan` | `danny` | Light signature theme vs. true-dark variant |
| `STATUSLINE_CAPS` | `flame` · `slant` · `rounded` · `pointed` | `flame` | End-cap style |
| `STATUSLINE_OS_ICON` | any glyph | auto | Override the OS badge icon |
| `STATUSLINE_CTX_ICON` | any glyph/emoji | `🧠` | Context-meter icon |
| `STATUSLINE_PIPE` | 256-color code | `250`/`240` | The `|` separator color |
| `STATUSLINE_FLAME` | hex `F2920D` / 256-num | auto | Flame accent — auto true-color on truecolor terminals (`COLORTERM`), else 256-color `208` |
| `STATUSLINE_BLUE` | 256-color code | theme | Model + repo segment color |
| `STATUSLINE_NEUTRAL` / `_FG` | 256-color code | theme | Grey badge/clock bg / text |
| `STATUSLINE_BADGE_BG/_FG`, `STATUSLINE_TIME_BG/_FG` | 256-color | theme | Per-segment fine control |
| `STATUSLINE_LCAP` / `_RCAP` | glyph(+ANSI) | theme | Raw end-cap override |

### Themes
- **`danny`** — light badge leading, a `238`-grey clock anchoring the right, teal-blue model/repo,
  orange-flame accent.
- **`dark-dan`** — true dark: dim grey neutrals, teal-blue model/repo, muted context colors, with
  the flame as the one bright accent.

## Demos

```bash
bash demos/preview.sh     # the line across several scenarios
bash demos/showcase.sh    # every theme × cap style
```

## Notes / caveats

- **Right-alignment** needs a terminal width. The script tries Claude Code's
  `terminal.width`/`cols`, then `$COLUMNS`, then `tput cols`, then falls back to `100`.
- **The reset countdown** only appears when Claude Code provides
  `rate_limits.five_hour.resets_at`; it degrades gracefully when absent.
- The script defensively `unset`s `GIT_DIR`/`GIT_WORK_TREE` (some shells export `GIT_DIR=./.git`,
  which breaks `git -C` in subdirectories).

## License

MIT — see [LICENSE](LICENSE).
