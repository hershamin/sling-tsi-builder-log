# Writing Posts

Posts are fancier build logs: a short prose intro on what was built, then a `## Photos` section of captioned images. One post per build session, almost always one post per git commit (markdown + images together).

This file is the house style — what posts here actually do. For the full set of Chirpy features available, see `docs/04-chirpy-syntax.md`. To generate a post from a photo batch with Claude, follow `docs/05-auto-posts.md`.

## Filename

`_posts/YYYY-MM-DD-kebab-slug.md`. Date prefix is required by Jekyll; slug becomes the URL (`/posts/<slug>/`).

## Front matter

```yaml
---
title: Rear Fuselage Bottom Skin
description: Rear fuselage bottom skin has been assembled.
date: 2026-05-31 18:11:00 -0600
categories: [Fuselage]
tags: [riveting, assembly]
---
```

- `date` — include time and offset. Site timezone is `America/Chicago`; build-log posts use `-0600`/`-0500`. Ordering on the site is by this timestamp.
- `categories` — **max two, hierarchical**: `[Section]` or `[Section, Subsection]`. Established values:
  - `Empennage` → `Horizontal Stabilizer`, `Elevator`, `Rudder`, `Vertical Stabilizer`
  - `Wing` → `Left Wing`, `Right Wing`
  - `Fuselage`
  - Reuse existing names exactly — they drive category archive pages.
- `tags` — lowercase, describe the *activity*, not the part (the part is what `categories` is for). Reuse the established set; only coin a new tag when nothing fits. Each tag gets a `/tags/:name/` archive page, so spelling/casing must match exactly. Current vocabulary by frequency:
  - Common: `assembly`, `riveting`, `tools`, `dimpling`
  - Occasional: `wiring`, `sealing`, `avionics`, `preparation`, `filling`
  - Rare: `plumbing`, `painting`, `inventory`, `service bulletin`, `inspection hatch`
  - A post usually carries 1–3 tags.

## Body pattern

1. One or two sentences of prose: what was assembled, any gotchas.
2. `## Photos` heading.
3. Repeated image + italic caption pairs:

```markdown
![alt-slug-1](/assets/img/posts/fuselage/rear-bottom-skin-1.jpg)
_Caption under the image._
```

The `_italic_` line immediately after an image renders as its caption (Chirpy convention).

When a session has distinct sub-tasks, **named sections replace the single `## Photos`**: each sub-task gets its own `##`/`###` heading with a sentence of prose and its own image+caption run (e.g. `## Tail Beacon Installation` → `### Bulb Socket` / `### Wiring`). Use flat `## Photos` only for a simple single-task session. Follow-ups added later go inline as a `**Update:**` line in the relevant section. Vendor/tool/proper names are italicized (`_Aircraft Spruce_`, `_sling technical_`); measurements use inline code (`` `3.2mm` ``).

## Optional bottom sections: Tools & Avionics

Add these **only when relevant**, at the very bottom after the photos:

- **`## Tools`** — when a tool is used for the *first time*. Document it so future posts can just reference it.
- **`## Avionics`** (electronics install) — description + where to buy. Often combined as **`## Avionics & Tools`** when a post does both.

Two formats, pick by item count:

Few items — bullet list, `* <what it's for>: [url](url)` (full URL as both text and link):

```markdown
## Tools
* Gel superglue to hold the springs during install: [https://...](https://...)
* Ring terminals to attach lights to wires: [https://www.amazon.com/dp/B086Z2Y1D6](https://www.amazon.com/dp/B086Z2Y1D6)
```

Many items (typical for avionics installs) — a table:

```markdown
## Avionics & Tools
| Name            | Description                          | Link               |
|:----------------|:-------------------------------------|:-------------------|
| Red Tail Beacon | PSA Enterprise red tail beacon       | https://...        |
| Multimeter      | For electrical connection testing    | https://...        |
```

A first-use tool may instead get inline prose + a photo of the tool (e.g. the impact dimpler) when it warrants explanation. Whenever a Tools/Avionics section appears, add the matching `tools` / `avionics` tag.

## Image storage

Put images under `assets/img/posts/<section>/[<subsection>/]`, mirroring categories:

```
assets/img/posts/fuselage/
assets/img/posts/empennage/{horizontal_stabilizer,elevator,rudder,vertical_stabilizer}/
assets/img/posts/wing/{left,right}/
```

Reference with an absolute site path starting `/assets/img/posts/...`. Folder names are lowercase with underscores; categories are Title Case with spaces — they correspond but are not identical strings.

## PDFs / attachments

Drop in `assets/files/` and link with `/assets/files/<name>.pdf`.