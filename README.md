# ForgeBuild

ForgeBuild is a parametric building-assembly modeling extension for SketchUp 2024+.

The product is organized in construction order around Floor, Wall, and Roof builders. CSI divisions remain attached to components for estimating, but they no longer define the modeling workflow.

## Included builders

- **Floor Builder:** slab-on-grade and equipment-pad placement; framed floors, beams, decks, and openings are next.
- **Wall Builder:** CMU and brick walls, veneers, pilasters, joints, lintels, bond beams, grouted cells, and reinforcing.
- **Roof Builder:** registered as the stable home for upcoming rafter, truss, layer, fascia, soffit, and drainage tools.

Masonry assemblies are drawn with a two-click line tool, accept typed lengths, retain editable estimating metadata, and calculate run length, wall area, volume, and reinforcing locations.

## Requirements

- SketchUp 2024 or newer
- Ruby 3.2-compatible runtime (provided by SketchUp 2024)
- SQLite adapter integration is planned behind `Database::Connection`; the extension does not silently install native dependencies.

## Development

```bash
ruby -Itest test/all_test.rb
rake syntax
rake package
```

`rake package` writes an installable `.rbz` file to `dist/`.

See [the architecture guide](docs/ARCHITECTURE.md), [roadmap](docs/ROADMAP.md), and [contribution guide](CONTRIBUTING.md).

## Status

Pre-alpha. Floor and Wall builders contain the active vertical slices. Roof tools and full edit/regenerate workflows remain on the roadmap.

## License

Proprietary commercial software. All rights reserved.
