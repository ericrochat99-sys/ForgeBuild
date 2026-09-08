# ForgeBuild

ForgeBuild is a modular commercial-building modeling extension for SketchUp 2024+.

This repository currently contains the production-oriented foundation: a safe SketchUp loader, application bootstrap, module registry, settings service, project model, starter HtmlDialog shell, and automated tests. Geometry builders and PDF/AI recognition will be added incrementally behind these boundaries.

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

Pre-alpha foundation (`0.1.1`). The builders are intentionally not advertised as complete.

## License

Proprietary commercial software. All rights reserved.
