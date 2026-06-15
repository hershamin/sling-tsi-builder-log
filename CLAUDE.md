# Sling TSi Builder Blog

A Jekyll/Chirpy static blog documenting the build of a Sling TSi kit aircraft (N1020W). Posts are photo-heavy build logs — essentially fancier construction journals. Hosted on GitHub Pages at `slingtsi.hershamin.me`.

## Tech Stack

- Jekyll static site, theme `jekyll-theme-chirpy` (~> 7.0) as a gem (not vendored)
- Ruby + Bundler; `html-proofer` for link checks
- GitHub Pages deploy via GitHub Actions

## Essential Commands

Typical workflow needs no local build — commit the post and push; Actions builds and publishes. Local commands are optional:

```bash
bundle install                  # setup / after Gemfile changes
bundle exec jekyll serve        # optional local preview at :4000
git submodule update --init     # populate assets/lib (fresh clone)
```

Deploy: push to default branch → Actions builds and publishes to Pages.

## Critical Constraints

- **One post per commit.** A typical change is a new `_posts/` markdown file plus its images, committed together. Don't refactor unrelated content.
- **Reuse existing `categories` and folder names exactly** — they drive archive pages and image paths. See `docs/02-posts.md`.
- Theme files (`_layouts`, `_includes`, SCSS) live in the gem, not this repo. Override by copying into a matching local path.
- `date:` front matter sets site ordering — include time + `-0600`/`-0500` offset (timezone `America/Chicago`).

## Context Index

| File | When to Load | When to Update | Priority |
|------|--------------|----------------|----------|
| `docs/01-architecture.md` | Before changing site structure, config, theme, or deploy | Directories added/removed, config or hosting changes | ⭐ |
| `docs/02-posts.md` | Before writing or editing any blog post or its images | Category/tag taxonomy or image-folder layout changes | ⭐⭐ |
| `docs/05-auto-posts.md` | Generating a post from a photo batch (the auto-writing workflow) | Inputs, filename→category map, or review steps change | ⭐ |
| `docs/04-chirpy-syntax.md` | Using Chirpy features beyond plain text + captioned images (callouts, embeds, media_subpath, image options) | Chirpy theme upgrade changes supported syntax | ⭐ |
| `docs/03-commands.md` | Building, serving, link-checking, or debugging deploy | Build tooling, gems, or CI workflow changes | ⭐ |

## Quick Answers (patterns emerging — update as needed)

| Problem | Where to Look |
|---------|---------------|
| How to add a new build-log post | `docs/02-posts.md` |
| Where post images go | `docs/02-posts.md` → "Image storage" |
| Local preview won't start / assets missing | `docs/03-commands.md` |