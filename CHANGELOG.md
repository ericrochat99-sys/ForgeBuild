# Changelog

All notable changes follow Semantic Versioning.

## [0.2.1] - 2026-09-08

### Changed

- Changed Check for Updates into a one-click in-app download and installation workflow.
- Added archive validation, backup, old-version removal, and automatic rollback on installation failure.
- Corrected the extension-manager version metadata to match the application version.

## [0.2.0] - 2026-09-08

### Added

- Shared builder contract and dynamic trade workspace discovery.
- Stable parametric-object metadata schema.
- Division 03 Concrete Builder workspace.
- Click-drag slab-on-grade and equipment-pad tools with typed dimensions.
- Concrete area and volume metadata and automated tests.

### Changed

- Reworked the main dialog into a builder and tool-selection workspace.

## [0.1.1] - 2026-09-08

### Fixed

- Corrected SketchUp's global `UI` namespace resolution so ForgeBuild loads successfully.

### Added

- Added a Check for Updates button that queries GitHub Releases and opens the latest RBZ download.
- Added regression tests for command registration and release comparison.

## [0.1.0] - 2026-09-08

### Added

- SketchUp extension loader and application bootstrap.
- Dependency container and extensible module registry.
- Settings, database, project-domain, command, and UI boundaries.
- Responsive light/dark HtmlDialog shell.
- Automated unit tests, syntax validation, and RBZ packaging task.
- Initial architecture and delivery roadmap.
