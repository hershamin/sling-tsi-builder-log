# Chirpy Post Syntax Reference

Full markdown/front-matter features Chirpy supports, for authoring (incl. auto-generated) posts. This blog uses only a slice today (prose + captioned images); the rest is available. Source of truth: https://chirpy.cotes.page/posts/write-a-new-post/ — check it if a feature behaves unexpectedly.

## Front matter (all fields)

```yaml
---
title: Post Title
description: Short summary.            # used by SEO + feed
date: 2026-05-31 18:11:00 -0600       # time + offset; sets ordering
categories: [Section, Subsection]     # max 2, hierarchical
tags: [activity1, activity2]          # lowercase activity tags
pin: true                             # pin to top of home (optional)
toc: false                            # disable per-post TOC (default on)
comments: false                       # disable Disqus on this post
math: true                            # enable MathJax (only if used)
mermaid: true                         # enable diagrams (only if used)
media_subpath: /assets/img/posts/fuselage   # prefix for relative media paths
image:                                # social/preview image (1200x630)
  path: /assets/img/posts/fuselage/rear-bottom-skin-1.jpg
  alt: alt text
  lqip: /path/to/lqip                 # optional blur placeholder
---
```

`media_subpath` is the big lever for auto-writing: set it once and reference images by bare filename in the body instead of repeating the full `/assets/img/posts/.../` path.

## Images

```markdown
![alt](rear-bottom-skin-1.jpg)
_Caption in italics directly below._
```

Modifiers (append `{: ... }` to the image line):

| Modifier | Effect |
|----------|--------|
| `{: w="700" h="400" }` | set dimensions |
| `{: .shadow }` | drop shadow (good for screenshots, not photos) |
| `{: .normal }` / `{: .left }` / `{: .right }` | alignment / float — **mutually exclusive with a caption** |
| `{: .light }` / `{: .dark }` | show only in that color theme |
| `{: lqip="/path" }` | low-quality placeholder while loading |

Caption = an `_italic_` line immediately after the image. Don't combine with alignment classes.

## Callouts / prompts

```markdown
> Cleco every hole before riveting.
{: .prompt-tip }
```

Types: `.prompt-tip` (green), `.prompt-info` (blue), `.prompt-warning` (yellow), `.prompt-danger` (red). Useful for build gotchas, torque specs, safety notes.

## Code, filepaths, files

- Filepath inline: `` `/assets/img/posts/`{: .filepath} ``
- Code block with a filename label:

````markdown
```yaml
title: ...
```
{: file="_posts/2026-05-31-example.md" }
````

- Hide line numbers: append `{: .nolineno }` to a code block.

## Media embeds

```markdown
{% include embed/youtube.html id='VIDEO_ID' %}      <!-- watch?v=ID -->
{% include embed/video.html src='/assets/files/clip.mp4' %}
{% include embed/audio.html src='/assets/files/clip.mp3' %}
```

YouTube/Twitch/Bilibili/Spotify supported via `embed/<platform>.html id='...'`. Local `video.html` takes `poster`, `title`, `autoplay=true`, `loop=true`, `muted=true`.

## Math & diagrams (rare here)

Set `math: true` then `$$ ... $$` (block: blank lines around it; inline: no blank lines). Set `mermaid: true` then a ```` ```mermaid ```` fenced block. Only enable the flag on posts that use them — it loads extra JS.