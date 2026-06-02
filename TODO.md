# TODO — before publishing

## Screenshots (capture in a terminal with a Nerd Font, dark bg; widen to ~115+ cols)

- [ ] **`docs/responsive.png`** — `bash demos/responsive.sh` → screenshot the width staircase
- [ ] **`docs/hero.png`** — `bash demos/preview.sh` → screenshot the top row (or a real session)
- [ ] *(optional)* **`docs/themes.png`** — `bash demos/showcase.sh` → danny vs dark-dan + cap styles

> ⚠️ The README image slots show a broken-image icon until these PNGs exist — add them
> **before** pushing public. (Each image has a text fallback nearby.)

## Publish

- [ ] Decide the final repo name (currently the placeholder `claude-code-statusline`; align with
      personal branding / job-search project before pushing)
- [ ] Push:
      ```bash
      gh repo create <name> --public \
        --source ~/sw/github/claude-code-statusline --remote origin --push
      ```
- [ ] Update the clone URL placeholder (`<you>`) in `README.md` install section

## Promote

- [ ] Write the LinkedIn post (self-contained Sonnet prompt already prepared)
