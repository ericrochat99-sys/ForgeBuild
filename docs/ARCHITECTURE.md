# Architecture

## Builder contract

Every trade workspace subclasses `ForgeBuild::Core::Builder`, provides stable identity and CSI division metadata, advertises its tools, and activates tools through the shared application container. Builders register with `ModuleRegistry`; the main dialog discovers them dynamically.

## Parametric objects

Generated groups store a stable object ID, builder and object type, dimensions, assembly data, CSI division, cost code, material information, and computed quantities in the `ForgeBuild.Object` attribute dictionary.

## Concrete vertical slice

`Builders::Concrete::Builder` exposes slab-on-grade and equipment-pad tools. `ConcreteRectangleTool` owns native SketchUp input, `ConcreteObjectService` owns construction and metadata, and `Geometry::RectangularPrism` owns geometry generation.

ForgeBuild separates responsibilities so builders can evolve independently:

- `core`: dependency container and module registration contracts.
- `ui`, `html`, `css`, `js`: presentation and the HtmlDialog bridge.
- `commands`: SketchUp menus, toolbars, and command wiring.
- `services`: application use cases that coordinate domain and infrastructure.
- `project`, `models`: domain state without direct UI dependencies.
- `geometry`, `builders`: SketchUp geometry operations, added by feature.
- `database`: SQLite adapter boundary, migrations, and repositories.
- `pdf`, `ai`, `importers`, `exporters`: isolated integration boundaries.
- `update`: signed release discovery, download, verification, and staged installation.

Each builder will register a descriptor and factory with `Core::ModuleRegistry`. The core application consumes the registry and does not require edits for every new module.

SketchUp model changes must run inside an operation so native Undo/Redo remains reliable. Geometry code must accept explicit inputs, return structured results, and keep metadata writes separate from mesh creation where practical.

SQLite will be introduced only after its SketchUp-compatible adapter and packaging strategy are validated. The connection boundary already prevents persistence details from leaking into builders.
