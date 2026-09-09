# ForgeBuild

ForgeBuild is a parametric building-assembly modeling extension for SketchUp 2024+.

Version 0.9.0 adds Phase 5 commercial information and delivery with model-wide takeoffs,
schedules, material lists, validation and clash warnings, and CSV/Excel-compatible exports.

Version 0.8.0 added the Phase 4 Roof Builder with commercial low-slope and specialty roofs,
structural framing, roof layers, openings, accessories, drainage, quantities, and regeneration.

Version 0.7.0 added the Phase 3 commercial Wall Builder with structural systems, layered and
rated construction, openings, accessories, sloped profiles, and wall-editing commands.

Version 0.6.0 added the Phase 2 Floor Builder on top of the shared assembly framework, with
concrete and foundation systems, structural framing, floor openings, coordination objects,
selected-face/polygon generation, editable parameters, quantities, and regeneration.

Version 0.5.0 completed the shared assembly framework with a selection-driven Property Inspector,
non-destructive editing and regeneration, lifecycle commands, three display modes, presets,
SQLite-backed project storage, legacy-object migrations, and coordinated materials and tags.

The product is organized in construction order around Floor, Wall, and Roof builders. CSI divisions remain attached to components for estimating, but they no longer define the modeling workflow.

## Included builders

- **Floor Builder:** concrete slabs and layers, foundations, joints, reinforcing, structural steel and wood framing, deck, precast, openings, penetrations, and coordination zones.
- **Wall Builder:** masonry, concrete, metal/wood framing, panels, layered/rated assemblies, openings, accessories, profiles, and editing commands.
- **Roof Builder:** low-slope and sloped roof assemblies, steel and wood framing, membranes, insulation, metal deck, openings, edge work, and drainage.

Masonry assemblies are drawn with a two-click line tool, accept typed lengths, retain editable estimating metadata, and calculate run length, wall area, volume, and reinforcing locations.

## Requirements

- SketchUp 2024 or newer
- Ruby 3.2-compatible runtime (provided by SketchUp 2024)
- The `sqlite3` Ruby library for persistent project and preset storage.

## Development

```bash
ruby -Itest test/all_test.rb
rake syntax
rake package
```

`rake package` writes an installable `.rbz` file to `dist/`.

See [the architecture guide](docs/ARCHITECTURE.md), [roadmap](docs/ROADMAP.md), and [contribution guide](CONTRIBUTING.md).

## Status

Pre-alpha. Floor, Wall, and Roof builders plus the Phase 5 commercial delivery workflow are active. Drawing-assisted modeling remains on the roadmap.

## License

Proprietary commercial software. All rights reserved.
