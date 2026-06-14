# Auto-Writing Posts with Claude

Procedure for generating a build-log post from a batch of photos. Goal: a draft that matches house style (`docs/02-posts.md`) with minimal input from Hersh. Output is a draft only — never commit or build (see [[sling-blog-workflow]] in memory; one post per commit, Hersh reviews first).

## Inputs Hersh provides

1. **A batch of photos** for one build session, named by convention: `<part>-<activity>-<n>.jpg` (e.g. `rudder-internal-riveting-1.jpg`). The leading keyword identifies the part → category + image folder.
2. **Date + rough time** of the session (e.g. "May 31, afternoon"). Drives the filename date prefix and `date:` front matter.
3. **Gotchas / notes** — supplied when Claude asks (see workflow step 3). One or two lines: surprises, sequence tips, torque/clecoing notes. This is what makes the prose real instead of generic.
4. **Tools / avionics (if any)** — for a first-use tool or an avionics install, the item name + buy link (and a one-line description). Becomes a bottom `## Tools` / `## Avionics` section. Claude asks; "none" skips it.

## Filename keyword → category → image folder

Infer from the photo's leading keyword (or the part shown). Reuse these exact strings — they drive archive pages and paths.

| Keyword in photo / part shown | `categories` | Image folder under `assets/img/posts/` |
|-------------------------------|--------------|----------------------------------------|
| horizontal stab, hstab, front-spar (tail) | `[Empennage, Horizontal Stabilizer]` | `empennage/horizontal_stabilizer/` |
| elevator | `[Empennage, Elevator]` | `empennage/elevator/` |
| rudder | `[Empennage, Rudder]` | `empennage/rudder/` |
| vertical stab, vstab | `[Empennage, Vertical Stabilizer]` | `empennage/vertical_stabilizer/` |
| left wing, aileron (L), flap (L) | `[Wing, Left Wing]` | `wing/left/` |
| right wing, aileron (R) | `[Wing, Right Wing]` | `wing/right/` |
| fuselage, tail-cone, skin (fuse) | `[Fuselage]` | `fuselage/` |

If a keyword doesn't map, ask rather than invent a new category. Pick `tags` (activity) from the established set in `docs/02-posts.md` — usually inferable from the `<activity>` part of the filename (`riveting`, `assembly`, `dimpling`, ...).

## Workflow

1. **Ingest** the photo batch. Parse keyword → category + folder. Confirm the inferred category back to Hersh in one line.
2. **Read every photo** (Read tool renders them). Note what each shows for captions and for the intro.
3. **Ask for gotchas + tools/avionics** — one prompt: "Anything notable this session? (surprises, sequence, fitment, mistakes to avoid) — and any first-use tools or avionics installed? (name + buy link)". Wait for the answer; fold gotchas into the prose intro and build a `## Tools` / `## Avionics` section from any items. If Hersh says "nothing", keep the intro to a plain one-liner and omit the bottom section.
4. **Place images**: copy/rename into the mapped folder as `<part>-<activity>-<n>.jpg`, sequential. Match existing naming.
5. **Write the post** at `_posts/YYYY-MM-DD-<slug>.md` using Hersh's date:
   - Front matter per `docs/02-posts.md` (`title`, `description`, `date` w/ time + offset, `categories`, `tags`).
   - Prose intro: 1–3 sentences, incorporating the gotchas. Honest — only claim what the photos + notes support.
   - `## Photos` then one `![alt](/assets/img/posts/.../file.jpg)` + `_caption_` per image, in build order.
6. **Stop.** Present the draft for review. Do not commit, do not run a build. Hersh verifies captions/date, then commits (one post per commit) and pushes.

## Caption + prose honesty

Captions describe what's visible; the intro adds the "why/how" from the gotchas. Never assert torque values, part numbers, or sequence that aren't in the photos or Hersh's notes — ask instead.