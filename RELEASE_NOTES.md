# ForgeBuild 1.2.5 — Parametric Push/Pull Assemblies

ForgeBuild assemblies can now be resized directly in the SketchUp modeling area without breaking their parametric data.

## Push/Pull Assembly

1. Select a ForgeBuild assembly.
2. Start Push/Pull Assembly from the toolbar, Properties panel, context-sensitive tools, or right-click menu.
3. Hover over an assembly face.
4. Click and drag the highlighted face.
5. Click again to apply, or type the desired dimension.

ForgeBuild determines whether the selected face controls length, width, height, thickness, or depth. It then updates the stored assembly parameter and regenerates the geometry.

- Live face highlighting and dimension feedback
- Typed-dimension entry
- Correct origin movement when resizing a starting face
- Metadata, materials, quantities, and display mode preserved
- Single-operation SketchUp Undo support
- Compatible with registered floor, wall, roof, and related ForgeBuild assemblies
