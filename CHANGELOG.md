# Changelog

## v1.2.10

### Fixed

- Start Drawing no longer attempts to parse wall and floor placement modes, snap toggles, or alignment values as numeric dimensions.


## v1.2.9

### Added

- Phase 4 + Phase 9 AI Edit Assistant in the selected assembly Property Inspector.
- Backend Ruby assembly edit assistant service for deterministic natural-language edit planning.
- Natural-language assembly edit analysis for common parameters including height, thickness, width, length, depth, elevation, fire rating, STC, R-value, pitch, slope, finish, material, and CMU/slab thickness language.
- One-click application of suggested parameter and metadata changes to the selected assembly.
- Apply-to-similar support for updating matching assemblies with the same builder and object type.
- AI-ready handoff prompt that packages the selected assembly, current parameters, requested edit, detected changes, warnings, questions, and safe-edit instructions.
- Smart workflow warnings and follow-up questions for openings, ratings, push/pull edits, fixed-side decisions, apply-to-similar edits, and missing dimensions.
- Quick access to Push/Pull and Regenerate from the AI edit panel.

### Improved

- Assembly parameter validation now supports assisted-edit fields including elevation, pitch, slope, STC, R-value, fire rating, system, material, finish, framing, insulation, sheathing, and other commercial assembly metadata.
- AI Edit Assistant now routes through Ruby services instead of being only a browser-side heuristic, while keeping a fallback analyzer for compatibility.
- Assisted edit results now separate geometry parameters from metadata changes and show ready/review-required safety status before applying.

## v1.2.8

### Added

- Phase 2 Trace Plan Mode workspace in the Plans & Drawings view.
- Guided trace workflow cards for import, elevation, calibration, tracing, and review.
- Selected-plan trace controls for calibration, elevation, focus guidance, and faded tracing UI.
- Quick trace buttons for floors, walls, roofs, openings, grids, and levels.
- Phase 2 trace styling for workflow cards, step indicators, and trace assembly buttons.

## v1.2.7

### Added

- Sticky placement settings for Floor Builder and Wall Builder.
- Live placement mode summary in the control bar and footer.
- Live dimension label feedback while previewing wall and linear floor placements.
- Finish Drawing and Cancel guidance controls in the placement panel.
- Esc key handling for more predictable placement-tool cancellation.

### Improved

- Cleaner placement control layout for floor and wall drawing tools.
- Better start-point, baseline, and assembly preview feedback while drawing.
- Saved drawing mode, snap angle, snap distance, and wall alignment per builder.
- Hardened dimension-label drawing so placement tools continue working across SketchUp draw_text variants.

## v1.2.6

### Added

- Drawing-style placement controls for Floor Builder and Wall Builder.
- Floor modes: Polygon, Arc, Rectangle, and Circle.
- Wall modes: Line, Polyline, Rectangle, and Arc.
- Snap to angle, snap to distance, and alignment controls.
- Placement options passed into SketchUp tools.

## Prior releases

Earlier release history is retained in the repository history.
