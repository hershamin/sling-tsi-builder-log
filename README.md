# sling-tsi-1-builder-log

Builder log for a Sling TSi kit plane (N1020W) — a 4-seat cross-country cruiser. Photo-heavy build journal: each post documents a build session. Live at **[slingtsi.hershamin.me](https://slingtsi.hershamin.me)**.

### Notes

* Jekyll site (Chirpy theme), hosted on GitHub Pages. Push to the default branch → GitHub Actions builds and deploys. No manual build needed.
* I'm no expert in plane building — I'm an Aerospace Engineer and a Software Engineer. I can help where needed, but I am **not an A&P**.

### Repository layout

| Path | What |
|------|------|
| `_posts/` | The build-log posts (`YYYY-MM-DD-slug.md`). |
| `assets/img/posts/` | Post images, foldered by section (empennage / wing / fuselage). |
| `assets/files/` | Linked PDFs. |
| `_config.yml` | Site config. |
| `CLAUDE.md` + `docs/` | Context for working in this repo (see below). |

### Local preview (optional)

```bash
bundle install
bundle exec jekyll serve   # http://127.0.0.1:4000
```

Fresh clone: `git submodule update --init` to populate `assets/lib/`.

### Writing posts with Claude

This repo is set up so [Claude Code](https://claude.com/claude-code) can draft build-log posts from a batch of photos.

**How to prompt:** drop the photo batch and say *"write a post from these photos."* Name photos `<part>-<activity>-<n>.jpg` (e.g. `rudder-internal-riveting-1.jpg`) so the part keyword maps to the right category/folder.

Claude will: confirm the inferred category → read every photo → ask one question (session gotchas + any first-use tools / avionics with buy links) → ask the date/time if not given → draft `_posts/YYYY-MM-DD-slug.md` with captions and any `## Tools` / `## Avionics` section → **stop for review**. It never commits or builds; review captions + date, then commit (one post per commit) and push.

Give it all up front for fewer round-trips:

> Write a post from the photos in `~/Desktop/rudder-batch/`. Session: June 12 afternoon. Gotcha: clecoed the bottom rib first to keep the skeleton true. New tool: pneumatic squeezer — https://amazon.com/dp/XXXX

Two things Claude always needs from you (can't infer): **date/time** and **gotchas**. Everything else comes from the filenames + photos.

The full procedure, house style, and category/tag conventions live in `docs/` — start at `CLAUDE.md`, then `docs/02-posts.md` (style) and `docs/05-auto-posts.md` (workflow).

### Reference (Chirpy)

* New post / front matter: https://chirpy.cotes.page/posts/write-a-new-post/
* Typography: https://github.com/cotes2020/jekyll-theme-chirpy/blob/master/_posts/2019-08-08-text-and-typography.md?plain=1