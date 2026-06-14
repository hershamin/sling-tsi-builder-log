# Commands & Deployment

Ruby/Jekyll site with a Bundler-managed gem theme.

**Typical workflow needs no local build.** Author the post + images, commit, push — GitHub Actions builds and deploys. The commands below are only for the rare case you want to preview or check links locally.

## Local development

```bash
bundle install        # first time, or after Gemfile changes
bundle exec jekyll serve   # serve at http://127.0.0.1:4000 with live reload
```

If `assets/lib/` is empty (fresh clone), pull the theme assets submodule:

```bash
git submodule update --init --recursive
```

## Build

```bash
bundle exec jekyll build   # output to _site/ (gitignored)
```

## Link checking

`html-proofer` is in the `:test` group of the `Gemfile`. After a build:

```bash
bundle exec htmlproofer _site
```

## Deployment

Push to the default branch. `.github/workflows/pages-deploy.yml` builds the site and publishes to GitHub Pages. No manual deploy step. The live site is `https://slingtsi.hershamin.me` (custom domain via `CNAME`).

## Notes

- `.nojekyll` is present so Pages serves the prebuilt `_site` from the Action rather than re-running its own Jekyll.
- Comments are Disqus (`shortname: sling-tsi-builder-blog`); nothing to run locally for them.