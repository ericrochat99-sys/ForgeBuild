# ForgeBuild 1.0.2 — In-Session Update Reloading

ForgeBuild 1.0.2 improves the one-click updater so routine patches can activate without restarting SketchUp.

## In-session reload

- Patch releases within the installed major/minor version are eligible for hot reload.
- ForgeBuild closes its active dialog before reloading to prevent callbacks from retaining obsolete UI objects.
- Models, geometry, services, catalogs, builders, tools, observers, project code, and dialog code reload from the newly installed extension.
- Catalogs load before builders so rebuilt tool definitions use the new catalog data.
- The installer reports whether the update was reloaded immediately or whether a restart is required.

## Restart safeguards

- Major and minor upgrades still request a restart because they may change startup registration, dependency wiring, or toolbar commands.
- If any in-session reload step fails, the installation remains complete and ForgeBuild asks for a restart instead of leaving the user with a false success message.

## Interface

- The update button displays **Updated & Reloaded** after a successful in-session activation.
