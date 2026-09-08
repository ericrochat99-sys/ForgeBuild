# ForgeBuild 0.2.0 — Concrete Builder Phase 1

ForgeBuild now has its first working trade workspace. Open ForgeBuild, choose **Concrete Builder**, select **Slab on Grade** or **Equipment Pad**, enter the thickness, and click **Place**. In the model, click two opposite corners or click once and type `width,length` in SketchUp's Measurements box.

Each placed group retains ForgeBuild metadata including its object type, dimensions, material, CSI division, cost code, area, and volume. This release also establishes the shared builder API that future trade modules will use.

This is a pre-alpha vertical slice. In-place geometry editing, SQLite-backed assembly defaults, and the remaining concrete tools are planned next.

## Installation

Build the RBZ with `rake package`, then in SketchUp open **Extensions → Extension Manager → Install Extension** and select the generated file.
