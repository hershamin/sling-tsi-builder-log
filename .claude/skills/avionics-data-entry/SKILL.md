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