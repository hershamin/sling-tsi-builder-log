# Avionics Diagrams — Design Spec

**Date:** 2026-06-14
**Project:** Sling TSi Builder Blog (Jekyll/Chirpy)
**Status:** Approved design, ready for implementation planning

## Goal

Document the aircraft's avionics from a **single source of truth** and render
multiple diagram/table views from it. Views must serve both the **blog** (web
pages) and an **offline/print reference** (browser print-to-PDF at the hangar).

Four views, one dataset:

| View | What | Renderer |
|------|------|----------|
| **A. System interconnect** | Logical block diagram — which box talks to which, edges colored by cable function | Mermaid (Liquid include) |
| **B. Physical location** | Aircraft outline with each box placed where it physically sits | Inline SVG (Liquid include) |
| **C. Wiring harness detail** | Pin-accurate connectors, individual wires, inline components | WireViz (offline step) |
| **D. Connector / pinout tables** | Per-connector pin → signal → color → destination | HTML (Liquid include) |

A fifth **BOM** view (bill of materials) is a near-free future add — all
components/connectors/wires are already in the data — but is **out of scope**
for the initial build.

## Architecture

```
_data/avionics/*.yml   ← single source of truth (split per subsystem)
        │
        ├─ Liquid includes (pure Jekyll, no custom plugin) ──► A interconnect (Mermaid)
        │                                                       B location (inline SVG)
        │                                                       D pinout tables (HTML)
        │
        └─ scripts/gen-harness.rb (offline) ──► WireViz YAML ──► wireviz ──► C harness SVG
                                                                  (committed to assets/)
```

**Design principles:**

- **A/B/D are pure Liquid includes.** Chirpy renders Mermaid natively; SVG and
  tables are Liquid loops over the data files. No custom Ruby plugin → the blog
  build stays pure-Ruby and GitHub-Pages-safe.
- **C is the only offline step.** A script transforms the master data into
  WireViz YAML, runs WireViz, and writes an SVG into `assets/`. The author
  commits the generated SVG. Python/Graphviz never touch the blog CI build.
- **One function→color palette**, defined once in `config.yml`, shared by all views.
- One commit per change still applies (project convention). Adding/updating an
  avionics view is its own commit.

## Data Model

### File layout (split per subsystem)

```
_data/avionics/
  config.yml        # GLOBAL: functions palette + locations
  buses.yml         # cross-subsystem shared buses (e.g. main CAN)
  nav.yml           # boxes + links for the nav subsystem
  power.yml         # boxes + links for power distribution
  audio.yml         # ... etc, one file per subsystem as needed
```

Jekyll auto-loads each file as `site.data.avionics.<name>`. Includes **merge**
across files: loop every file, collect its `boxes` and `links`. Box `id` is
**globally unique**, so a link defined in `buses.yml` may reference boxes
defined in `nav.yml`. `config.yml` holds the shared palette and locations.

### `config.yml` — global palette + locations

```yaml
functions:                      # shared palette: function -> color (hex)
  can:    "#1f77b4"
  power:  "#d62728"
  ground: "#111111"
  serial: "#2ca02c"
  audio:  "#9467bd"
  rf:     "#ff7f0e"

locations:                      # configurable physical regions (for view B)
  panel:    { label: "Instrument Panel", x: 120, y: 70 }
  tailcone: { label: "Tailcone",         x: 250, y: 78 }
  lwing:    { label: "Left Wing",        x: 60,  y: 95 }
```

### Subsystem file — boxes, antennas, links

```yaml
boxes:
  - id: pfd                     # globally unique
    name: "Garmin G3X PFD"
    location: panel             # key into config.locations
    pos: { x: 110, y: 60 }      # optional fine offset for view B
    part_no: "010-00..."        # optional
    connectors:
      - id: J1
        name: "Main"
        type: "D-sub 25"        # optional
        gender: "M"             # optional
        pins:
          1: { signal: "CAN-H", function: can }
          2: { signal: "CAN-L", function: can }
          3: { signal: "+12V",  function: power }
          4: { signal: "GND",   function: ground }

antennas:
  - id: gps_ant
    name: "GPS Antenna"
    location: tailcone
    connects: gps               # RF link to a box id

links:                          # point-to-point AND multidrop, unified
  - id: can_main
    function: can               # bundle default; per-wire may override
    topology: daisy             # daisy = shared conductor through all nodes; omit for 2-node point-to-point
    gauge: 22
    wires:                      # conductors defined ONCE, shared across the bus
      - { signal: CAN-H, color: "WH/BU", label: "" }   # label optional
      - { signal: CAN-L, color: "WH/OR" }
    nodes:                      # ORDER = chain order for daisy
      - { box: pfd, connector: J1, pins: { CAN-H: 1, CAN-L: 2 } }
      - { box: gps, connector: P1, pins: { CAN-H: 5, CAN-L: 6 } }
      - { box: ap,  connector: P2, pins: { CAN-H: 3, CAN-L: 4 } }
    components:
      - { type: resistor, value: "120Ω", across: [CAN-H, CAN-L], at: pfd }
      - { type: resistor, value: "120Ω", across: [CAN-H, CAN-L], at: ap }

  # Power/ground fan-out = MANY point-to-point links sharing a common box
  # (bus bar / ground block). Each branch is its OWN wire with own gauge/breaker.
  - id: pfd_pwr
    function: power
    wires: [ { signal: "+12V", color: RD } ]
    nodes:
      - { box: cb_panel, connector: B1, pins: { "+12V": 3 } }
      - { box: pfd,      connector: J1, pins: { "+12V": 3 } }
    components:
      - { type: breaker, value: "5A",     inline: "+12V", between: [cb_panel, pfd] }
      - { type: diode,   value: "1N4001", inline: "+12V", between: [cb_panel, pfd], dir: "cb_panel->pfd" }
  - id: gps_pwr
    function: power
    wires: [ { signal: "+12V", color: RD } ]
    nodes:
      - { box: cb_panel, connector: B1, pins: { "+12V": 4 } }
      - { box: gps,      connector: P1, pins: { "+12V": 2 } }
    components:
      - { type: breaker, value: "3A", inline: "+12V", between: [cb_panel, gps] }
```

### Model rules

- **Links unify cables and buses.** 2 nodes = point-to-point cable; N nodes =
  shared-conductor multidrop bus (`topology: daisy`). Omit `topology` for the
  trivial 2-node case.
- **Two distinct topologies — do not confuse them:**
  - **Shared-conductor bus** (e.g. CAN) → ONE link, `topology: daisy`, `wires`
    threaded through every node. The same physical conductors pass through all
    boxes.
  - **Fan-out distribution** (e.g. power, ground) → MANY point-to-point links
    sharing one common box (bus bar / CB panel / ground block). Each branch is
    its **own** wire with its own `gauge`, `color`, and `components` (breaker).
    View A renders this as a star **automatically** because every edge converges
    on the common box — no `star` topology keyword exists or is needed.
- **Each node maps `signal → pin`** (not raw `from_pin`/`to_pin`), so one wire
  threads through many connectors at different pin numbers — this is how a
  daisy-chained CAN bus is expressed.
- **Inline components** attach to a link via `components`:
  - `across: [sigA, sigB] at: <box>` — sits between two conductors at one node
    end (e.g. 120Ω CAN terminator).
  - `inline: <signal> between: [boxA, boxB]` — in series on one wire segment
    (e.g. breaker, diode). `dir` gives diode polarity.
  - `type` is extensible: resistor / diode / breaker / … (this aircraft uses
    resettable **circuit breakers**, not fuses; breakers are modeled inline-only,
    not as located panel items).
- **Mid-wire splice** (one physical conductor splitting into branches) is a
  future `splice` node type — **out of scope** for the initial build.
- **Optional fields** (all skippable): `part_no` (box), `type`/`gender`
  (connector), `label` (wire).

## Renderers

### A — System interconnect (`_includes/avionics/interconnect.html`)

- Merge all `links` across files.
- Emit a Mermaid `flowchart`: one node per box (+ antennas as a distinct shape),
  edges per link.
  - `daisy`: edges between adjacent nodes in `nodes` order.
  - point-to-point: single edge. Power/ground fan-out is just many such edges
    converging on the common box, which reads as a star with no special handling.
- Color each edge by `link.function` using `linkStyle` indexed per edge, pulling
  hex from `config.functions`.
- Optional edge label: breaker rating where present. Terminators/diodes omitted
  to keep the diagram clean.
- Output is a Markdown ```` ```mermaid ```` block; Chirpy renders it on web and
  in print.

### B — Physical location (`_includes/avionics/location.html`)

- Emit inline `<svg>`.
- Base aircraft outline: a static SVG path (top or side view) included as a
  backdrop. (Decision deferred to planning: simple hand-drawn path vs. tracing a
  Sling planform image.)
- Place each box at `config.locations[box.location]` offset by `box.pos`.
- Antennas drawn with a distinct marker at their location.
- Draw faint connection lines following each link's `nodes` order.
- Liquid positions elements by interpolating data values into SVG attributes
  (`plus`/`minus` filters for region-base + offset math).

### C — Wiring harness detail (`scripts/gen-harness.rb` → WireViz)

- Offline Ruby script reads `_data/avionics/*.yml`, builds a WireViz YAML doc:
  - WireViz `connectors` from each box's `connectors` (pins → pinlabels).
  - WireViz `cables` from each `link` (wires, gauge, colors).
  - **Daisy chains** map to WireViz multi-connector connection sets (a wire-set
    threaded across all `nodes`).
  - **Inline components** map to WireViz `additional_components` (drawn + BOM).
  - Wire colors derived from `link.function` via the shared palette (or explicit
    `wire.color` when given).
- Runs `wireviz` to produce SVG (+ optional PNG) into `assets/img/avionics/`.
- Author commits the generated artifact; it is embedded in a post as an image.
- Invocation: a documented command (e.g. `ruby scripts/gen-harness.rb`),
  requiring Python + WireViz + Graphviz installed locally. Not part of CI.

### D — Connector / pinout tables (`_includes/avionics/pinouts.html`)

- Merge all `boxes`. For each connector, emit an HTML table: pin, signal,
  function (color-swatched from palette), and destination (resolved by finding
  the link/node that lands on that pin).
- Per-link **components** row/footnote listing inline passives.
- Accepts an optional include param to render a single connector
  (`{% include avionics/pinouts.html connector="pfd.J1" %}`) or all.

## Usage in posts

```liquid
{% include avionics/interconnect.html %}
{% include avionics/location.html %}
{% include avionics/pinouts.html %}            <!-- or connector="pfd.J1" -->
![CAN harness](/assets/img/avionics/can_main.svg)   <!-- view C, pre-generated -->
```

## Authoring skill — interactive YAML entry (`avionics-data-entry`)

The YAML files are authored via Claude, so the build includes an **interactive
skill** that walks the user through edits instead of guessing values. It is the
primary way data gets added/changed.

**Trigger:** user wants to add or edit an avionics box, connector, link, bus,
or inline component.

**Behavior — ask, never invent:**

- Walk one question at a time through the schema for the thing being added.
  Never fabricate part numbers, pin assignments, wire colors, gauges, or
  ratings — ask the user for each.
- **Offer choices from existing data** so the user picks rather than retypes:
  existing box ids, connector ids, `config.functions` keys, `config.locations`
  keys. Adding a new function/location prompts to extend `config.yml`.
- **Validate references** before writing: every `link.nodes[].box`/`connector`
  must exist; every pin referenced must be declared on that connector; signals
  in `components` must exist in the link's `wires`.
- **Route to the right file:** boxes/links go in the relevant
  `_data/avionics/<subsystem>.yml` (ask which subsystem; offer existing ones);
  cross-subsystem buses go in `buses.yml`; palette/locations go in `config.yml`.
- **Confirm the diff** with the user before writing, and keep each change
  focused (one box, one link) to fit the project's one-logical-change habit.
- Knows the schema from this spec; on schema changes, the skill is updated too.

This is the data-side counterpart to the existing auto-post workflow
(`docs/05-auto-posts.md`).

## Offline / print reference

- A dedicated page (a `_tabs` entry or a single aggregating post) embeds all four
  views together.
- Web view = the rendered page; offline reference = browser **print-to-PDF** of
  that page. Mermaid and SVG both print cleanly.

## Verification / success criteria

1. **Data loads:** `bundle exec jekyll build` succeeds with sample
   `_data/avionics/*.yml` present; no Liquid errors.
2. **View A:** interconnect Mermaid renders; edges are colored per function;
   a daisy bus shows all member boxes connected.
3. **View B:** location SVG renders; boxes appear at their configured regions;
   moving a box's `location`/`pos` moves it in output.
4. **View C:** `gen-harness.rb` produces a WireViz SVG for a daisy CAN bus with
   two 120Ω terminators and a breaker-protected power line shown as inline
   components.
5. **View D:** pinout table lists every pin with correct signal, function color,
   and resolved destination.
6. **Single source:** changing one pin/color/location in the YAML updates every
   affected view (A/B/D on next build; C on next `gen-harness.rb` run).
7. **CI clean:** GitHub Actions blog build needs no Python/Graphviz; only view C
   generation does, and it runs offline.
8. **Authoring skill:** adding a box/link via the skill asks for every value,
   offers existing ids/functions/locations as choices, rejects an invalid box or
   pin reference, and writes to the correct subsystem file after confirmation.

## Out of scope (initial build)

- BOM view (view 5) — data supports it; defer.
- Multiple aircraft — single aircraft (N1020W) only.
- Auto-running WireViz in CI.
- Interactive/clickable diagrams beyond what Mermaid provides by default.

## Open decisions for planning

- Aircraft outline source for view B (hand-drawn SVG path vs. traced planform).
- Whether `buses.yml` is one file or buses live in their primary subsystem file.
- WireViz color mapping detail (function palette → WireViz color codes).