# ForgeBuild 0.1.1

This maintenance release fixes the startup error caused by Ruby namespace resolution and adds an in-app Check for Updates button connected to official GitHub Releases.

- ForgeBuild now loads correctly in SketchUp 2024+.
- Check for Updates reports whether the installed version is current.
- When an update exists, the button opens the official downloadable RBZ asset.

## Installation

Build the RBZ with `rake package`, then in SketchUp open **Extensions → Extension Manager → Install Extension** and select the generated file.
