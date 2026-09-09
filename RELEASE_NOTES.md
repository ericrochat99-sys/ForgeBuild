# ForgeBuild 1.0.0 — Phase 6 Drawing-Assisted Modeling

ForgeBuild 1.0.0 is the first production release. It adds a drawing-assisted workflow for turning architectural, structural, and MEP underlays into coordinated Floor, Wall, and Roof Builder objects.

## Forge product-family branding

- New angular ForgeBuild mark derived from the visual language used by ForgeCase.
- Forge Black `#2D3036`, Forge Bronze `#A77747`, white, and light-gray interface palette.
- Montserrat/Inter-style typography, square architectural panels, restrained bronze accents, and consistent form controls.
- “FORGE BUILD — Commercial Building Solutions” header and “Built for What’s Next” tagline.

## Drawing setup

- Register PDF, image, DWG, and DXF underlays with discipline, sheet, page, revision, and source metadata.
- Calibrate imported drawings by clicking two known points and entering the actual dimension.
- Store scale, rotation, origin, visibility, and persistent entity references with the SketchUp model.
- Track drawing revisions and addenda with comparison-ready history.

## Tracing and recognition

- Trace floors, walls, roofs, openings, column grids, and levels directly over drawing underlays.
- Generate regular parametric ForgeBuild assemblies from traces so editing, regeneration, quantities, materials, and exports continue to work.
- Parse OCR output or pasted annotations for dimensions, elevations, room names, wall types, detail references, assembly tags, and grid lines.
- Suggest commercial wall and roof assemblies from annotations.
- Require explicit user confirmation for every recognized or suggested assembly; recognition never creates geometry automatically.

## Coordination

- Compare recognized drawing features with the model.
- Report matched features, drawing-only conditions, model-only objects, and unresolved scope.
- Use the new Drawing Assistant workspace and toolbar command for the complete workflow.

## Validation

- Added automated tests for drawing registration, calibration, revisions, annotation parsing, confirmation state, and model comparison.
