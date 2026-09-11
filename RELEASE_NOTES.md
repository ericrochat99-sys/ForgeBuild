# ForgeBuild 1.2.8 — Phase 2 Plan Tracing Workflow

ForgeBuild v1.2.8 starts the Phase 2 plan-tracing workflow so imported plans can be used as a more guided modeling surface.

## Trace Plan Mode

- Added a dedicated Trace Plan Mode workspace inside Plans & Drawings.
- Added guided workflow cards for Import, Elevation, Calibrate, Trace, and Review.
- Added selected-plan controls for calibration, elevation updates, focus guidance, and faded tracing UI.
- Added quick trace actions for Floor Area, Wall Run, Roof Area, Openings, Grid Lines, and Levels.
- Added phase-specific trace styling for workflow cards, step indicators, selected-plan tools, and trace assembly buttons.

## Workflow Impact

This release makes the drawing-import workflow easier to follow before tracing assemblies. It gives the user a clearer sequence: import the plan, set the correct elevation, calibrate it, then trace model assemblies from the drawing underlay.

## Notes

This is the first Phase 2 usability release. The trace buttons use the existing SketchUp tracing callbacks and assembly creation services; the next Phase 2 work should continue into plan-layer controls, plan opacity/locking behavior, and richer trace previews before create.
