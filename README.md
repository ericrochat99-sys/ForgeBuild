# ForgeBuild

ForgeBuild is a modular commercial-building modeling extension for SketchUp 2024+.

The extension includes a shared builder contract, extensible module registry, parametric-object metadata schema, a Division 03 Concrete Builder, and a Division 04 Masonry Builder.

## Included builders

- **Division 03 — Concrete:** slab-on-grade and equipment-pad placement.
- **Division 04 — Masonry:** CMU walls, brick walls, brick veneer, stone veneer, pilasters, control joints, lintels, bond beams, grouted cells, and reinforcing.

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

Pre-alpha. Division 03 Concrete and Division 04 Masonry builders are active vertical slices; additional assemblies and trade builders remain on the roadmap.

## License

Proprietary commercial software. All rights reserved.
