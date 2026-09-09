# Changelog

## [0.7.0] - 2026-09-09

### Added

- Phase 3 Wall Builder catalog with 51 commercial wall systems, layers, openings, joints, and accessories.
- CMU, reinforced masonry, concrete, metal-stud, shaft, chase, pony, furred, structural-stud, wood, IMP, tilt-up, precast, ICF, SIP, storefront, curtain-wall, and glazed-partition systems.
- Exterior and interior layer tools for sheathing, barriers, insulation, rainscreens, veneers, panels, EIFS, stucco, gypsum, cement board, and acoustical panels.
- Door, frame, borrowed-lite, storefront, window, louver, access-panel, and overhead-door opening objects.
- Fire/smoke ratings, STC, R-value, UL/GA design, security classification, CSI, cost-code, material, and quantity metadata.
- Sloped and gable wall geometry using independently editable start and end heights.
- Stud-layout geometry and counts for framed walls.
- Wall stretch, split, offset, join, connect, align, renumber, and schedule-summary commands.
- Parent/child relationships between host walls and layers, openings, joints, and accessories.

### Changed

- Routed current and legacy masonry objects through the unified Wall Object Service.
- Added text-property support to builder option forms.

## [0.6.0] - 2026-09-08

### Added

- Complete Floor Builder catalog spanning concrete, foundations, structural framing, openings, and coordination.
- Rectangle, linear-run, point-placement, and selected-face/polygon floor workflows.
- Slab-on-grade parameters for slopes, depressions, thickened edges, and turndowns.
- Elevated slabs, composite and non-composite slabs, deck profiles, underslab layers, and reinforcing zones.
- Spread/continuous footings, grade beams, foundation walls, piers, equipment foundations, pits, sumps, drains, and trenches.
- Steel beams, steel joists with schematic web geometry, bridging, deck, precast, wood joist, and floor-truss systems.
- Openings, sleeves, blockouts, curbs, opening reinforcement, bearing conditions, and MEP coordination zones.
- Parent/child relationships between host floors and associated layers, openings, joints, and coordination objects.
- Floor-system filtering in the builder workspace and builder-specific estimating metadata and quantities.

### Changed

- Routed all new and legacy Floor Builder objects through a shared regeneration service.
- Added slope, turndown, deck-rib, circular-object, and open-web geometry primitives.

## [0.5.0] - 2026-09-08

### Added

- Selection-driven Property Inspector with editable assembly metadata and parameters.
- Edit, regenerate, move, copy, and delete workflows for selected assemblies.
- 2D, simplified 3D, and detailed 3D display modes.
- ForgeBuild right-click context menu and expanded toolbar commands with custom icons.
- Named assembly presets, default presets, SQLite project/preset schema, and migrations.
- Automatic migration of legacy Concrete and Masonry objects into Floor and Wall assemblies.
- Centralized material creation and SketchUp tag assignment.

### Changed

- Expanded the shared framework around Floor, Wall, and Roof Builder identities.
- Updated assembly regeneration to preserve the owning group and transformation.

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
