# ForgeBuild 0.3.1 — Reusable Builder Window

This patch fixes the ForgeBuild workspace becoming empty after placing the first object.

Starting a Concrete or Masonry tool now hides the builder window instead of permanently closing its SketchUp `HtmlDialog`. Reopening ForgeBuild from the toolbar restores the same populated workspace, allowing you to switch tools and continue working.

The selected placement tool also remains active after creating an object, so you can place multiple objects of the same type without returning to the dialog each time.

If the ForgeBuild window is manually closed with the X, the extension now discards that closed dialog and creates a fresh, fully initialized workspace the next time ForgeBuild is opened.
