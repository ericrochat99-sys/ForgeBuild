# Changelog

All notable changes follow Semantic Versioning.

## [0.4.0] - 2026-09-08

### Changed

- Reorganized ForgeBuild around Floor, Wall, and Roof building assemblies instead of CSI trade builders.
- Migrated slab and equipment-pad tools into Floor Builder.
- Migrated all masonry systems into Wall Builder while retaining CSI metadata.
- Updated the main workspace language and builder metadata for the assembly workflow.

### Added

- Registered the Roof Builder as the stable home for upcoming roof systems.
- Added schema-versioned parent/child and source-parameter metadata for generated assemblies.
- Added a builder-agnostic regeneration dispatcher and regression tests.

## [0.3.1] - 2026-09-08

### Fixed

- Kept the ForgeBuild dialog reusable after a tool is activated instead of closing and retaining an invalid HtmlDialog.
- Rebuilds the main dialog after the user manually closes it, preventing an empty builder registry on reopen.
- Added a regression test for repeated tool activation workflow.

## [0.3.0] - 2026-09-08

### Added

- Division 04 Masonry Builder with CMU wall, brick wall, brick veneer, stone veneer, pilaster, control joint, lintel, bond beam, grouted cell, and reinforcing tools.
- Two-click angled masonry placement with typed-length input.
- Division 04 object metadata, CSI cost codes, wall area, volume, and reinforcing-location quantities.
- Masonry service regression tests.

### Changed

- Extended the shared builder tool schema and dialog renderer to support builder-defined option fields.

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
