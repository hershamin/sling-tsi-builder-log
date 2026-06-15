# Avionics Diagrams Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Render four avionics views (system interconnect, physical location, wiring harness, pinout tables) plus an interactive YAML-authoring skill, all from one per-subsystem data source.

**Architecture:** A single source of truth lives in `_data/avionics/*.yml` (split per subsystem). Views A (Mermaid interconnect), B (inline-SVG location), and D (pinout tables) are pure Liquid includes — no custom plugin — so the GitHub Pages build stays pure-Ruby. View C (pin-accurate harness) is an offline `scripts/gen-harness.rb` step that transforms the data into WireViz YAML, runs WireViz, and commits an SVG into `assets/`. An `avionics-data-entry` project skill drives all YAML edits interactively.

**Tech Stack:** Jekyll + Chirpy (Liquid, kramdown, Mermaid), Ruby (gen-harness + minitest), WireViz + Graphviz (offline only), YAML.

> **Commit policy for this plan (user override):** Do NOT commit per task. Implement and verify every task, then make **one single commit on `master`** in the final task. The project's usual "one post per commit" rule is intentionally waived here.

> **Reference:** Design spec at `docs/superpowers/specs/2026-06-14-avionics-diagrams-design.md`. Read it before starting.

> **Resolved open decisions:** (1) View-B aircraft outline = a simple hand-drawn top-view SVG path (no traced image). (2) Cross-subsystem buses live in `_data/avionics/buses.yml`. (3) WireViz wire colors come straight from each `wire.color` (WireViz-native 2-letter codes, `/` stripped); the hex `functions` palette is used only by A/B/D. (4) View B v1 renders placed boxes + antennas only; faint connection lines are deferred (noted in docs).

---

## File Structure

**Create:**
- `_data/avionics/config.yml` — global function→color palette + named locations
- `_data/avionics/nav.yml` — seed boxes, power fan-out links, antenna
- `_data/avionics/buses.yml` — seed daisy-chained CAN bus
- `_includes/avionics/pinouts.html` — View D (tables)
- `_includes/avionics/interconnect.html` — View A (Mermaid)
- `_includes/avionics/location.html` — View B (SVG)
- `_includes/avionics/aircraft-outline.svg` — static backdrop path for View B
- `_tabs/avionics.md` — reference page assembling A/B/D (also the verification surface)
- `scripts/gen-harness.rb` — View C generator (data → WireViz YAML → SVG)
- `scripts/test_gen_harness.rb` — minitest for the pure transform function
- `.claude/skills/avionics-data-entry/SKILL.md` — interactive authoring skill
- `docs/06-avionics.md` — system documentation

**Modify:**
- `CLAUDE.md` — add `docs/06-avionics.md` to the Context Index + a Quick Answers row

**Responsibilities:** each include owns exactly one view and re-derives the merged box/link list itself (includes can't share state cleanly). `gen-harness.rb` splits a pure `build_wireviz_doc(data)` function (unit-tested) from the CLI/render shell-out (smoke-checked).

---

## Task 1: Seed data (source of truth)

**Files:**
- Create: `_data/avionics/config.yml`
- Create: `_data/avionics/nav.yml`
- Create: `_data/avionics/buses.yml`

- [ ] **Step 1: Write `_data/avionics/config.yml`**

```yaml
# Global palette + locations shared by all avionics views.
functions:               # function -> hex color (used by views A/B/D)
  can:    "#1f77b4"
  power:  "#d62728"
  ground: "#111111"
  serial: "#2ca02c"
  rf:     "#ff7f0e"
locations:               # named physical regions; x/y are View-B base coords
  panel:    { label: "Instrument Panel", x: 150, y: 70 }
  tailcone: { label: "Tailcone",         x: 380, y: 95 }
  lwing:    { label: "Left Wing",        x: 90,  y: 150 }
```

- [ ] **Step 2: Write `_data/avionics/nav.yml`**

```yaml
boxes:
  - id: pfd
    name: "G3X PFD"
    location: panel
    pos: { x: 0, y: -18 }
    connectors:
      - id: J1
        name: "Main"
        pins:
          1: { signal: "CAN-H", function: can }
          2: { signal: "CAN-L", function: can }
          3: { signal: "+12V",  function: power }
          4: { signal: "GND",   function: ground }
  - id: gps
    name: "GPS 175"
    location: panel
    pos: { x: 0, y: 22 }
    connectors:
      - id: P1
        name: "Main"
        pins:
          1: { signal: "+12V",  function: power }
          2: { signal: "GND",   function: ground }
          5: { signal: "CAN-H", function: can }
          6: { signal: "CAN-L", function: can }
  - id: cb_panel
    name: "CB Panel"
    location: panel
    pos: { x: -90, y: 2 }
    connectors:
      - id: B1
        name: "Bus"
        pins:
          3: { signal: "+12V", function: power }
          4: { signal: "+12V", function: power }
antennas:
  - id: gps_ant
    name: "GPS Ant"
    location: tailcone
    connects: gps
links:
  # Power fan-out: many point-to-point links sharing cb_panel (renders as a star).
  - id: pfd_pwr
    function: power
    wires: [ { signal: "+12V", color: "RD" } ]
    nodes:
      - { box: cb_panel, connector: B1, pins: { "+12V": 3 } }
      - { box: pfd,      connector: J1, pins: { "+12V": 3 } }
    components:
      - { type: breaker, value: "5A", inline: "+12V", between: [cb_panel, pfd] }
  - id: gps_pwr
    function: power
    wires: [ { signal: "+12V", color: "RD" } ]
    nodes:
      - { box: cb_panel, connector: B1, pins: { "+12V": 4 } }
      - { box: gps,      connector: P1, pins: { "+12V": 1 } }
    components:
      - { type: breaker, value: "3A", inline: "+12V", between: [cb_panel, gps] }
```

- [ ] **Step 3: Write `_data/avionics/buses.yml`**

```yaml
links:
  # Shared-conductor daisy bus: the SAME two wires thread through both boxes.
  - id: can_main
    function: can
    topology: daisy
    gauge: 22
    wires:
      - { signal: "CAN-H", color: "WH/BU" }
      - { signal: "CAN-L", color: "WH/OR" }
    nodes:
      - { box: pfd, connector: J1, pins: { "CAN-H": 1, "CAN-L": 2 } }
      - { box: gps, connector: P1, pins: { "CAN-H": 5, "CAN-L": 6 } }
    components:
      - { type: resistor, value: "120Ω", across: ["CAN-H", "CAN-L"], at: pfd }
      - { type: resistor, value: "120Ω", across: ["CAN-H", "CAN-L"], at: gps }
```

- [ ] **Step 4: Verify the data parses**

Run: `ruby -ryaml -e 'Dir["_data/avionics/*.yml"].each { |f| YAML.load_file(f); puts "ok #{f}" }'`
Expected: three `ok _data/avionics/...yml` lines, no exception.

---

## Task 2: View D — pinout tables + reference page skeleton

**Files:**
- Create: `_includes/avionics/pinouts.html`
- Create: `_tabs/avionics.md`

- [ ] **Step 1: Write the reference page (verification surface)**

Create `_tabs/avionics.md`:

```markdown
---
icon: fas fa-microchip
order: 5
mermaid: true
---

# Avionics

## Pinouts

{% include avionics/pinouts.html %}
```

- [ ] **Step 2: Write `_includes/avionics/pinouts.html`**

Merges all boxes across data files; one table per connector; resolves each pin's destination from `links`. Optional `connector="box.conn"` filter. Lines that become markdown table rows are flush-left so kramdown parses the table.

```liquid
{%- assign fns = site.data.avionics.config.functions -%}
{%- for f in site.data.avionics -%}{%- assign d = f[1] -%}
{%- for b in d.boxes -%}
{%- for c in b.connectors -%}
{%- assign key = b.id | append: "." | append: c.id -%}
{%- if include.connector == nil or include.connector == key -%}

### {{ b.name }} — {{ c.id }}{% if c.name %} ({{ c.name }}){% endif %}

| Pin | Signal | Function | Destination |
|----:|--------|----------|-------------|
{% for p in c.pins -%}
{%- assign pin = p[0] -%}{%- assign info = p[1] -%}
{%- assign dest = "" -%}
{%- for ff in site.data.avionics -%}{%- assign dd = ff[1] -%}
{%- for l in dd.links -%}
{%- for n in l.nodes -%}
{%- if n.box == b.id and n.connector == c.id -%}
{%- for np in n.pins -%}
{%- if np[1] == pin -%}
{%- for n2 in l.nodes -%}
{%- unless n2.box == b.id and n2.connector == c.id -%}
{%- assign dest = dest | append: n2.box | append: "." | append: n2.connector | append: ", " -%}
{%- endunless -%}
{%- endfor -%}
{%- endif -%}
{%- endfor -%}
{%- endif -%}
{%- endfor -%}
{%- endfor -%}
{%- endfor -%}
| {{ pin }} | {{ info.signal }} | <span style="color:{{ fns[info.function] }}">&#9679;</span> {{ info.function }} | {{ dest | split: ", " | uniq | join: ", " }} |
{% endfor %}
{%- endif -%}
{%- endfor -%}
{%- endfor -%}
{%- endfor -%}
```

- [ ] **Step 3: Build and verify the tables render**

Run: `bundle exec jekyll build 2>&1 | tail -5 && grep -o 'CAN-H' _site/avionics/index.html | head -1`
Expected: build completes with no Liquid error; prints `CAN-H`.

- [ ] **Step 4: Verify destination resolution**

Run: `grep -A12 'G3X PFD' _site/avionics/index.html | grep -o 'gps.P1'`
Expected: prints `gps.P1` (PFD J1 pin 1 CAN-H resolves to gps.P1 via `can_main`).

If the table does not render as a table (rows appear as literal `|` text), the row line `| {{ pin }} | ... |` has leading whitespace — ensure it is flush-left in the include source. Rebuild and re-verify.

---

## Task 3: View A — system interconnect (Mermaid)

**Files:**
- Create: `_includes/avionics/interconnect.html`
- Modify: `_tabs/avionics.md`

- [ ] **Step 1: Add the include to the reference page**

In `_tabs/avionics.md`, add above the `## Pinouts` heading:

```markdown
## System Interconnect

{% include avionics/interconnect.html %}
```

- [ ] **Step 2: Write `_includes/avionics/interconnect.html`**

Emits a fenced `mermaid` flowchart: a node per box and antenna, an edge per link (daisy → adjacent-node edges; point-to-point → one edge), each edge colored by function via an indexed `linkStyle`. The opening fence and content must be flush-left so kramdown/Chirpy treat it as a Mermaid block.

```liquid
{%- assign fns = site.data.avionics.config.functions -%}
```mermaid
flowchart LR
{% for f in site.data.avionics %}{% assign d = f[1] %}{% for b in d.boxes %}  {{ b.id }}["{{ b.name }}"]
{% endfor %}{% for a in d.antennas %}  {{ a.id }}(["{{ a.name }}"])
{% endfor %}{% endfor %}
{%- assign ei = 0 -%}{%- assign styles = "" -%}
{% for f in site.data.avionics %}{% assign d = f[1] %}
{%- for a in d.antennas -%}  {{ a.id }} --- {{ a.connects }}
{% assign styles = styles | append: "linkStyle " | append: ei | append: " stroke:" | append: fns.rf | append: ",stroke-width:2px" | append: ";;" %}{% assign ei = ei | plus: 1 %}
{%- endfor -%}
{%- for l in d.links -%}{%- assign color = fns[l.function] -%}
{%- if l.topology == "daisy" -%}
{%- for n in l.nodes -%}{%- unless forloop.first -%}  {{ prev }} --- {{ n.box }}
{% assign styles = styles | append: "linkStyle " | append: ei | append: " stroke:" | append: color | append: ",stroke-width:2px" | append: ";;" %}{% assign ei = ei | plus: 1 %}
{%- endunless -%}{%- assign prev = n.box -%}{%- endfor -%}
{%- else -%}  {{ l.nodes[0].box }} --- {{ l.nodes[1].box }}
{% assign styles = styles | append: "linkStyle " | append: ei | append: " stroke:" | append: color | append: ",stroke-width:2px" | append: ";;" %}{% assign ei = ei | plus: 1 %}
{%- endif -%}
{%- endfor -%}
{% endfor %}
{% assign lines = styles | split: ";;" %}{% for s in lines %}{% if s != "" %}{{ s }};
{% endif %}{% endfor %}```
```

- [ ] **Step 3: Build and verify the flowchart**

Run: `bundle exec jekyll build 2>&1 | tail -3 && grep -o 'flowchart LR' _site/avionics/index.html`
Expected: build succeeds; prints `flowchart LR`.

- [ ] **Step 4: Verify edges and per-function coloring**

Run: `grep -o 'pfd --- gps' _site/avionics/index.html | head -1 && grep -o 'linkStyle [0-9]* stroke:#1f77b4' _site/avionics/index.html | head -1`
Expected: prints `pfd --- gps` (the CAN daisy edge) and a `linkStyle N stroke:#1f77b4` (CAN blue) line.

If Mermaid edges render on one line / break, the whitespace controls collapsed needed newlines — adjust `{%- -%}` vs `{% %}` so each box decl, edge, and `linkStyle` lands on its own line, then re-verify.

---

## Task 4: View B — physical location (SVG)

**Files:**
- Create: `_includes/avionics/aircraft-outline.svg`
- Create: `_includes/avionics/location.html`
- Modify: `_tabs/avionics.md`

- [ ] **Step 1: Write `_includes/avionics/aircraft-outline.svg`**

A simple top-view outline (fuselage + wings + tail) used as a backdrop.

```html
<path d="M40 95 L300 80 Q360 80 440 95 Q360 110 300 110 L40 95 Z" fill="none" stroke="#888" stroke-width="1.5"/>
<path d="M120 95 L150 150 L175 150 L160 95 Z" fill="none" stroke="#888" stroke-width="1"/>
<path d="M120 95 L150 40 L175 40 L160 95 Z" fill="none" stroke="#888" stroke-width="1"/>
<path d="M430 95 L450 75 L455 75 L445 95 Z" fill="none" stroke="#888" stroke-width="1"/>
<path d="M430 95 L450 115 L455 115 L445 95 Z" fill="none" stroke="#888" stroke-width="1"/>
```

- [ ] **Step 2: Add the include to the reference page**

In `_tabs/avionics.md`, add below the interconnect block and above `## Pinouts`:

```markdown
## Physical Location

{% include avionics/location.html %}
```

- [ ] **Step 3: Write `_includes/avionics/location.html`**

Places each box at its location base + `pos` offset; antennas as labeled circles. (Connection lines deferred to a later enhancement.)

```liquid
{%- assign locs = site.data.avionics.config.locations -%}
<svg viewBox="0 0 480 200" width="100%" style="max-width:680px" font-family="sans-serif">
{% include avionics/aircraft-outline.svg %}
{%- for f in site.data.avionics -%}{%- assign d = f[1] -%}
{%- for b in d.boxes -%}
{%- assign base = locs[b.location] -%}
{%- assign px = b.pos.x | default: 0 -%}{%- assign py = b.pos.y | default: 0 -%}
{%- assign bx = base.x | plus: px -%}{%- assign by = base.y | plus: py -%}
  <rect x="{{ bx }}" y="{{ by }}" width="70" height="20" rx="3" fill="#2b3a55" stroke="#7aa2f7"/>
  <text x="{{ bx | plus: 35 }}" y="{{ by | plus: 14 }}" text-anchor="middle" fill="#cfe" font-size="10">{{ b.name }}</text>
{%- endfor -%}
{%- for a in d.antennas -%}
{%- assign base = locs[a.location] -%}
  <circle cx="{{ base.x }}" cy="{{ base.y }}" r="6" fill="#ff7f0e"/>
  <text x="{{ base.x }}" y="{{ base.y | minus: 9 }}" text-anchor="middle" fill="#888" font-size="9">{{ a.name }}</text>
{%- endfor -%}
{%- endfor -%}
</svg>
```

- [ ] **Step 4: Build and verify placement**

Run: `bundle exec jekyll build 2>&1 | tail -3 && grep -o '<svg viewBox="0 0 480 200"' _site/avionics/index.html && grep -o 'G3X PFD' _site/avionics/index.html | wc -l`
Expected: build succeeds; the svg tag prints; `G3X PFD` count is ≥ 2 (once in location SVG, once in pinouts).

- [ ] **Step 5: Verify location config drives output**

Run: `grep -o 'GPS Ant' _site/avionics/index.html`
Expected: prints `GPS Ant` (antenna rendered at the tailcone location).

---

## Task 5: View C — WireViz harness generator

**Files:**
- Create: `scripts/gen-harness.rb`
- Create: `scripts/test_gen_harness.rb`

- [ ] **Step 1: Write the failing test**

Create `scripts/test_gen_harness.rb`:

```ruby
require "minitest/autorun"
require_relative "gen_harness_lib"

class TestBuildWireviz < Minitest::Test
  def data
    {
      "config" => { "functions" => { "can" => "#1f77b4" } },
      "nav" => {
        "boxes" => [
          { "id" => "pfd", "connectors" => [{ "id" => "J1", "pins" => { 1 => { "signal" => "CAN-H" }, 2 => { "signal" => "CAN-L" } } }] },
          { "id" => "gps", "connectors" => [{ "id" => "P1", "pins" => { 5 => { "signal" => "CAN-H" }, 6 => { "signal" => "CAN-L" } } }] },
        ],
      },
      "buses" => {
        "links" => [{
          "id" => "can_main", "function" => "can", "topology" => "daisy", "gauge" => 22,
          "wires" => [{ "signal" => "CAN-H", "color" => "WH/BU" }, { "signal" => "CAN-L", "color" => "WH/OR" }],
          "nodes" => [
            { "box" => "pfd", "connector" => "J1", "pins" => { "CAN-H" => 1, "CAN-L" => 2 } },
            { "box" => "gps", "connector" => "P1", "pins" => { "CAN-H" => 5, "CAN-L" => 6 } },
          ],
          "components" => [{ "type" => "resistor", "value" => "120Ω", "across" => ["CAN-H", "CAN-L"], "at" => "pfd" }],
        }],
      },
    }
  end

  def test_builds_doc_for_can_main
    doc = build_wireviz_doc(data, "can_main")
    assert doc["connectors"].key?("pfd.J1"), "expected pfd.J1 connector"
    assert doc["connectors"].key?("gps.P1"), "expected gps.P1 connector"
    assert doc["cables"].key?("can_main"), "expected can_main cable"
    assert_equal ["WHBU", "WHOR"], doc["cables"]["can_main"]["colors"], "colors stripped of slash"
    assert_equal 2, doc["cables"]["can_main"]["wirecount"]
    # daisy chain expressed as connector -> cable -> connector in connections
    flat = doc["connections"].flatten.map(&:to_s).join(" ")
    assert_includes flat, "pfd.J1"
    assert_includes flat, "gps.P1"
    # terminator captured as an additional component
    assert(doc["additional_components"].any? { |c| c["type"].include?("resistor") }, "expected resistor component")
  end
end
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `ruby scripts/test_gen_harness.rb`
Expected: FAIL — `cannot load such file -- gen_harness_lib` (library not written yet).

- [ ] **Step 3: Write the library `scripts/gen_harness_lib.rb`**

```ruby
# Pure transform: merged avionics data + a link id -> a WireViz YAML doc (Hash).
# Kept separate from the CLI so it is unit-testable without running wireviz.

def wireviz_color(c)
  c.to_s.gsub("/", "").upcase   # "WH/BU" -> "WHBU"; WireViz-native 2-letter codes
end

def find_connector(data, box_id, conn_id)
  data.each do |name, section|
    next unless section.is_a?(Hash) && section["boxes"]
    section["boxes"].each do |b|
      next unless b["id"] == box_id
      b["connectors"].each { |c| return [b, c] if c["id"] == conn_id }
    end
  end
  [nil, nil]
end

def find_link(data, link_id)
  data.each do |name, section|
    next unless section.is_a?(Hash) && section["links"]
    section["links"].each { |l| return l if l["id"] == link_id }
  end
  nil
end

def build_wireviz_doc(data, link_id)
  link = find_link(data, link_id) or raise "unknown link #{link_id}"
  doc = { "connectors" => {}, "cables" => {}, "connections" => [], "additional_components" => [] }

  # Connectors: one per node, pinlabels from the box connector definition.
  link["nodes"].each do |n|
    box, conn = find_connector(data, n["box"], n["connector"])
    raise "missing #{n['box']}.#{n['connector']}" unless conn
    key = "#{n['box']}.#{n['connector']}"
    pins = conn["pins"].keys.sort_by(&:to_i)
    doc["connectors"][key] = {
      "pinlabels" => pins.map { |p| conn["pins"][p]["signal"] },
      "pins" => pins,
    }
  end

  # Cable: the shared wire set.
  doc["cables"][link_id] = {
    "wirecount" => link["wires"].length,
    "gauge" => link["gauge"] ? "#{link['gauge']} AWG" : nil,
    "colors" => link["wires"].map { |w| wireviz_color(w["color"]) },
  }.compact

  # Connections: chain the cable through every node (daisy = multi-connector set).
  signals = link["wires"].map { |w| w["signal"] }
  set = []
  link["nodes"].each_with_index do |n, i|
    pins = signals.map { |s| n["pins"][s] }
    set << { "#{n['box']}.#{n['connector']}" => pins }
    set << { link_id => (1..signals.length).to_a } unless i == link["nodes"].length - 1
  end
  doc["connections"] << set

  # Inline components -> WireViz additional_components (drawn + BOM).
  (link["components"] || []).each do |c|
    doc["additional_components"] << {
      "type" => "#{c['type']} #{c['value']}".strip,
      "qty" => 1,
    }
  end

  doc
end
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `ruby scripts/test_gen_harness.rb`
Expected: PASS (1 run, assertions pass).

- [ ] **Step 5: Write the CLI wrapper `scripts/gen-harness.rb`**

Loads the real data, builds a doc per link, writes WireViz YAML, and runs `wireviz` if installed.

```ruby
#!/usr/bin/env ruby
# View C generator: _data/avionics/*.yml -> WireViz YAML -> SVG in assets/img/avionics/.
# Requires `wireviz` (pip install wireviz) + Graphviz on PATH for the render step.
require "yaml"
require "fileutils"
require_relative "gen_harness_lib"

ROOT = File.expand_path("..", __dir__)
OUT  = File.join(ROOT, "assets", "img", "avionics")
TMP  = File.join(ROOT, ".avionics-wireviz")

data = {}
Dir[File.join(ROOT, "_data", "avionics", "*.yml")].each do |f|
  data[File.basename(f, ".yml")] = YAML.load_file(f)
end

link_ids = data.values.flat_map { |s| (s.is_a?(Hash) && s["links"]) ? s["links"].map { |l| l["id"] } : [] }
abort "no links found" if link_ids.empty?

FileUtils.mkdir_p(OUT)
FileUtils.mkdir_p(TMP)
have_wireviz = system("which wireviz > /dev/null 2>&1")

link_ids.each do |id|
  doc = build_wireviz_doc(data, id)
  yml = File.join(TMP, "#{id}.yml")
  File.write(yml, doc.to_yaml)
  puts "wrote #{yml}"
  if have_wireviz
    system("wireviz", yml) or warn "wireviz failed for #{id}"
    %w[svg png html].each do |ext|
      src = File.join(TMP, "#{id}.#{ext}")
      FileUtils.mv(src, File.join(OUT, "#{id}.#{ext}")) if File.exist?(src)
    end
  end
end

puts have_wireviz ? "Harness SVGs in #{OUT}" : "WireViz not installed — wrote WireViz YAML to #{TMP} only. Install wireviz to render SVGs."
```

- [ ] **Step 6: Run the generator and verify WireViz YAML output**

Run: `ruby scripts/gen-harness.rb && grep -l 'can_main' .avionics-wireviz/can_main.yml && grep -o 'WHBU' .avionics-wireviz/can_main.yml | head -1`
Expected: prints the generator messages, the `can_main.yml` path, and `WHBU` (color slash stripped). If `wireviz` is installed, also confirm `ls assets/img/avionics/can_main.svg`.

- [ ] **Step 7: Add generated-artifact note**

Append `.avionics-wireviz/` to `.gitignore` (intermediate WireViz YAML is not committed; only the rendered SVGs under `assets/img/avionics/` are).

Run: `printf '\n.avionics-wireviz/\n' >> .gitignore && grep -c '.avionics-wireviz' .gitignore`
Expected: prints `1`.

---

## Task 6: Authoring skill — interactive YAML entry

**Files:**
- Create: `.claude/skills/avionics-data-entry/SKILL.md`

- [ ] **Step 1: Write the skill**

```markdown
---
name: avionics-data-entry
description: Use when adding or editing an avionics box, connector, link/cable, bus, antenna, or inline component in _data/avionics/*.yml. Interactively collects every value from the user — never invents pins, colors, gauges, part numbers, or ratings — validates references, and writes to the correct subsystem file.
---

# Avionics Data Entry

Interactive authoring for `_data/avionics/*.yml`. Schema reference:
`docs/superpowers/specs/2026-06-14-avionics-diagrams-design.md` and `docs/06-avionics.md`.

## Hard rules

- **Ask, never invent.** Never fabricate part numbers, pin numbers, signals, wire
  colors, gauges, breaker/resistor ratings, or locations. If a value is unknown,
  ask the user.
- **Offer existing choices.** Before asking for a function, location, box id, or
  connector id, read `_data/avionics/*.yml` and present the existing values as a
  pick-list. Adding a new function or location means editing `config.yml` — confirm first.
- **Validate before writing.** Every `link.nodes[].box`/`connector` must already
  exist; every referenced pin must be declared on that connector; every signal in
  `components` (`across`/`inline`) must exist in the link's `wires`.
- **One logical change at a time.** Add one box, or one link — not a batch.
- **Confirm the diff.** Show the exact YAML to be added and which file it goes in;
  get approval before writing.

## Routing

- Boxes / antennas / subsystem-local links → `_data/avionics/<subsystem>.yml`
  (ask which subsystem; offer existing filenames).
- Cross-subsystem buses (e.g. main CAN) → `_data/avionics/buses.yml`.
- New function colors or locations → `_data/avionics/config.yml`.

## Flow (adding a box)

1. Ask: subsystem file (offer existing). 2. Ask: id (unique — check it is not
taken), name, location (offer existing keys), optional part_no.
3. For each connector: id, optional name/type/gender, then each pin: number,
signal, function (offer palette keys). 4. Show the assembled YAML + target file.
5. On approval, append to the file. 6. Remind: rebuild for A/B/D; run
`ruby scripts/gen-harness.rb` to refresh View C.

## Flow (adding a link / bus)

1. Ask shared vs fan-out:
   - **Shared conductor** (CAN daisy): one link, `topology: daisy`, wires threaded
     through ordered nodes.
   - **Fan-out** (power/ground): one point-to-point link per branch, each sharing
     the common box; do NOT use a single multi-node link.
2. Collect wires (signal + color), gauge, ordered nodes (box/connector + signal→pin
   map — validate each pin exists), and components (terminators via `across/at`,
   series breakers/diodes via `inline/between`).
3. Validate all references, show YAML + target file, confirm, write.
```

- [ ] **Step 2: Verify the skill file is valid**

Run: `head -4 .claude/skills/avionics-data-entry/SKILL.md`
Expected: shows YAML front matter with `name: avionics-data-entry` and a `description:` line.

---

## Task 7: Documentation

**Files:**
- Create: `docs/06-avionics.md`
- Modify: `CLAUDE.md`

- [ ] **Step 1: Write `docs/06-avionics.md`**

```markdown
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

- **A interconnect** — `{% include avionics/interconnect.html %}` (needs `mermaid: true`).
- **B location** — `{% include avionics/location.html %}`.
- **D pinouts** — `{% include avionics/pinouts.html %}` or `connector="pfd.J1"`.
- **C harness** — run `ruby scripts/gen-harness.rb` (needs `wireviz` + Graphviz),
  commit the SVG from `assets/img/avionics/`, embed as a normal image.

The `_tabs/avionics.md` page assembles A/B/D as the printable reference (browser print-to-PDF).

## Deferred / future

- BOM view, View-B connection lines, mid-wire `splice` node type.
```

- [ ] **Step 2: Add `docs/06-avionics.md` to the CLAUDE.md Context Index**

In `CLAUDE.md`, in the `## Context Index` table, add this row after the `05-auto-posts.md` row:

```markdown
| `docs/06-avionics.md` | Before editing avionics data or diagrams, or running the harness generator | Data schema, view includes, or generator workflow changes | ⭐ |
```

- [ ] **Step 3: Add a Quick Answers row in CLAUDE.md**

In the `## Quick Answers` table, add:

```markdown
| How to add/edit an avionics box or cable | Use the `avionics-data-entry` skill; see `docs/06-avionics.md` |
```

- [ ] **Step 4: Verify the edits landed**

Run: `grep -c '06-avionics' CLAUDE.md && grep -c 'avionics-data-entry' CLAUDE.md`
Expected: prints `1` then `1` (one Context Index row mentioning the doc; one Quick Answers row mentioning the skill).

---

## Task 8: Full build + single commit

**Files:** none new.

- [ ] **Step 1: Clean build with everything in place**

Run: `bundle exec jekyll build 2>&1 | tail -5`
Expected: `done in ... seconds`, no Liquid/Mermaid errors.

- [ ] **Step 2: Final cross-view sanity check**

Run: `for s in 'flowchart LR' 'pfd --- gps' 'viewBox="0 0 480 200"' 'CAN-H' 'gps.P1'; do grep -q "$s" _site/avionics/index.html && echo "ok: $s" || echo "MISSING: $s"; done`
Expected: five `ok:` lines, no `MISSING:`.

- [ ] **Step 3: Stage and commit everything in one commit on master**

```bash
git add _data/avionics _includes/avionics _tabs/avionics.md scripts/gen-harness.rb scripts/gen_harness_lib.rb scripts/test_gen_harness.rb .claude/skills/avionics-data-entry docs/06-avionics.md docs/superpowers CLAUDE.md .gitignore
git status
git commit -m "$(cat <<'EOF'
feat: avionics diagrams from single data source

Add per-subsystem avionics data (_data/avionics/*.yml) and four views:
- A system interconnect (Mermaid, edges colored by function)
- B physical location (inline SVG)
- C wiring harness (scripts/gen-harness.rb -> WireViz)
- D connector pinout tables
Plus _tabs/avionics.md reference page, interactive avionics-data-entry
skill, and docs/06-avionics.md.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 4: Verify the commit**

Run: `git log --oneline -1 && git show --stat HEAD | tail -20`
Expected: one new commit on `master` listing all created/modified files.

---

## Self-Review Notes

- **Spec coverage:** views A/B/C/D (Tasks 2–5), single source split per subsystem (Task 1), function→color palette (config.yml, used in every view), daisy bus + power fan-out + inline breaker/resistor (seed data + gen-harness + pinouts), print reference (`_tabs/avionics.md`), authoring skill (Task 6), docs (Task 7). BOM view, View-B lines, and `splice` are explicitly deferred per spec.
- **Type/name consistency:** `build_wireviz_doc(data, link_id)` defined in `scripts/gen_harness_lib.rb`, required by both the test and `gen-harness.rb`; data keys (`boxes`/`links`/`nodes`/`wires`/`components`/`pins`) match the spec schema and the seed YAML throughout.
- **Known fragility:** Liquid whitespace control drives Mermaid newlines and markdown-table layout (Tasks 2–3); each task includes a build+grep verification and a fix hint if output collapses.