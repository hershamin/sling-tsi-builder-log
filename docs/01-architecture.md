# Architecture

A Jekyll static site using the **Chirpy** theme (gem `jekyll-theme-chirpy`), hosted on GitHub Pages at `slingtsi.hershamin.me` (see `CNAME`). It is a builder log — a photo-heavy blog documenting the construction of a Sling TSi kit aircraft.

## Layout

| Path | Purpose |
|------|---------|
| `_posts/` | All blog posts (`YYYY-MM-DD-slug.md`). ~75 posts, the heart of the repo. |
| `_tabs/` | Top-nav pages: `about`, `archives`, `categories`, `tags`. Rarely edited. |
| `_data/` | `share.yml`, `contact.yml` — sidebar/footer link config. |
| `_plugins/posts-lastmod-hook.rb` | Sets `last_modified_at` from git history. |
| `assets/img/posts/` | Post images, foldered by section (see `docs/02-posts.md`). |
| `assets/files/` | Linked PDFs (e.g. Sling service notifications). |
| `assets/lib/` | Git submodule → `chirpy-static-assets` (theme JS/CSS deps). |
| `_config.yml` | Site config: title, author, disqus, permalinks, archives. |
| `.github/workflows/pages-deploy.yml` | CI build + deploy to GitHub Pages. |

## Theme is a gem, not vendored

The Chirpy theme lives in the installed gem, not this repo. Layouts, includes, and SCSS come from there. To override theme behavior, copy the file from the gem into a matching local path. Do not expect `_layouts/` or `_includes/` here — they are inherited.

## Permalinks

Posts resolve to `/posts/:title/` (the slug, not the date). Defined under `defaults` in `_config.yml`. Categories and tags get archive pages via `jekyll-archives` at `/categories/:name/` and `/tags/:name/`.

## What work usually looks like

Nearly every change is **one new post per commit**: a markdown file plus its images, added together. Structural/theme changes are rare. See `docs/02-posts.md` for the post recipe.