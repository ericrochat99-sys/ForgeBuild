# ForgeBuild 1.1.1 — Import Directly into the Drawing Workspace

ForgeBuild 1.1.1 changes plan import into a direct import-and-calibrate workflow.

## New import flow

1. Choose **Import & Calibrate** in the Drawing Assistant.
2. Select the PDF, TIFF, image, DWG, or DXF plan.
3. ForgeBuild registers and selects the imported document in the SketchUp modeling area.
4. The camera fits the complete imported document in view.
5. The ForgeBuild dialog closes so it no longer covers the plan.
6. Calibration activates immediately.
7. Click two endpoints of a known plan dimension and enter its actual length.

The registered drawing remains available through **Calibrate Again** for later correction.

## Reliability

- ForgeBuild now verifies that SketchUp created an identifiable entity for the imported plan.
- A clear error appears if the native importer reports success without placing a document in the modeling area.
- Added regression coverage for automatic selection and zoom-to-plan behavior.
