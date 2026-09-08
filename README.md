# ForgeBuild

ForgeBuild is a modular commercial-building modeling extension for SketchUp 2024+.

This repository contains the production-oriented foundation and the first trade workspace. ForgeBuild now includes a shared builder contract, extensible module registry, parametric-object metadata schema, and a Division 03 Concrete Builder with slab-on-grade and equipment-pad placement tools.

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

Pre-alpha Phase 1 (`0.2.0`). The Concrete Builder is an initial vertical slice; additional concrete assemblies and trade builders remain on the roadmap.

## License

Proprietary commercial software. All rights reserved.
