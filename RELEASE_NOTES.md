# ForgeBuild 1.1.0 — Native SketchUp Inference

ForgeBuild 1.1.0 makes assembly placement and drawing tracing behave like native SketchUp drawing tools.

## Native model interaction

- Snap to SketchUp vertices, endpoints, midpoints, edges, intersections, guide points, guide lines, and faces.
- Use SketchUp's red, green, and blue axes while placing floors, walls, roofs, masonry, and concrete objects.
- Display native inference markers and inference tooltips at the point ForgeBuild will actually use.
- Keep typed distances aligned with the current inferred direction.

## Plans and photos

- Pick points directly on imported plans and photo/image entities.
- Keep subsequent points associated with the first inferred anchor.
- Press Down Arrow to constrain tracing to the elevation of the imported drawing plane.
- Trace raster linework manually while retaining native SketchUp snapping wherever actual model or guide geometry exists.

## Keyboard constraints

- Hold Shift to lock the current SketchUp inference.
- Press Right Arrow for the red axis.
- Press Left Arrow for the green axis.
- Press Up Arrow for the blue axis.
- Press Down Arrow to remain on the current drawing or image plane.

## Consistency

- Concrete, floor, masonry, wall, roof, plan tracing, and drawing calibration now share one inference implementation.
- Previews and generated geometry use the same constrained coordinate.
