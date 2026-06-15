# Avionics Diagrams

One data source → four views. Source of truth: `_data/avionics/*.yml`
(split per subsystem). Full design: `docs/superpowers/specs/2026-06-14-avionics-diagrams-design.md`.

## Data files

- `config.yml` — `functions` (function→hex color) + `locations` (named regions, View-B coords).
- `<subsystem>.yml` (e.g. `nav.yml`) — `boxes`, `antennas`, subsystem-local `links`.
- `buses.yml` — cross-subsystem shared buses.

## Editing

Use the `avionics-data-entry` skill — it asks for every value and validates
references. Don't hand-edit unless you know the schema.

Key model points:
- A **link** = a wire run. 2 nodes = point-to-point; `topology: daisy` = one
  conductor set threaded through N nodes (CAN bus).
- **Power/ground fan-out** = many point-to-point links sharing one box (CB panel /
  bus bar). View A renders this as a star automatically — there is no `star` keyword.
- Each node maps `signal → pin`. Inline components: `across:[a,b] at:box`
  (terminator) or `inline:sig between:[a,b]` (breaker/diode). This aircraft uses
  circuit **breakers**, not fuses.

## Views

- **A interconnect** — `{% raw %}{% include avionics/interconnect.html %}{% endraw %}` (needs `mermaid: true`).
- **B location** — `{% raw %}{% include avionics/location.html %}{% endraw %}`.
- **D pinouts** — `{% raw %}{% include avionics/pinouts.html %}{% endraw %}` or `connector="pfd.J1"`.
  Emitted as HTML `<table>` (not markdown) to avoid kramdown whitespace issues.
- **C harness** — run `ruby scripts/gen-harness.rb` (needs `wireviz` + Graphviz),
  commit the SVG from `assets/img/avionics/`, embed as a normal image. Without
  WireViz installed it writes WireViz YAML to `.avionics-wireviz/` only.

The `_tabs/avionics.md` page assembles A/B/D as the printable reference (browser print-to-PDF).

## Tests

`ruby scripts/test_gen_harness.rb` covers the WireViz transform.

## Status (as of 2026-06-14)

- Seed data in `_data/avionics/*.yml` is **sample/placeholder** (pfd, gps,
  cb_panel, one CAN bus, power fan-out) — replace with real N1020W avionics via
  the `avionics-data-entry` skill.
- Views A/B/D render live on `_tabs/avionics.md`.
- View C (WireViz) **not yet rendered**: WireViz/Graphviz not installed, so
  `gen-harness.rb` currently writes WireViz YAML only. No SVGs committed in
  `assets/img/avionics/` yet.
- View D emits HTML `<table>` (not markdown pipes) — kramdown whitespace via
  Liquid was unworkable.

## Deferred / future

- BOM view, View-B connection lines, mid-wire `splice` node type.