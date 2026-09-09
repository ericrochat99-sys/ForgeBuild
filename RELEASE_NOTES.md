# ForgeBuild 1.0.1 — Drawing Import Fix

ForgeBuild 1.0.1 fixes plan import failures introduced by the Phase 6 Drawing Assistant.

## Fixed

- Removed the nested SketchUp undo operation that produced “Undo operation already open” when importing a plan.
- Allows SketchUp's native importer to finish before ForgeBuild starts its metadata-registration operation.
- Limits rollback to the ForgeBuild registration operation so a failed registration does not corrupt SketchUp's importer state.
- Added regression coverage that verifies importing occurs before any ForgeBuild operation begins.

## Verified source case

The reported plan is an 8400 × 6000 pixel, 200-DPI, one-page, Group 4-compressed bilevel TIFF. The original failure occurred before TIFF decoding, so the operation-order fix applies directly to this file.
