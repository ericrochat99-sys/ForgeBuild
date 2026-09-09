# Architecture

## Builder contract

Every assembly workspace subclasses `ForgeBuild::Core::Builder`, provides stable identity and applicable CSI division metadata, advertises its tools, and activates tools through the shared application container. The three primary identities are `floor`, `wall`, and `roof`.

## Parametric objects

Generated groups store a schema version, stable object ID, parent/child relationships, builder and object type, source parameters, dimensions, assembly data, display mode, CSI information, materials, and computed quantities in `ForgeBuild.Object`.

## Assembly vertical slices

`Builders::Floor::Builder` exposes the existing slab-on-grade and equipment-pad tools. `Builders::Wall::Builder` owns the current masonry systems and will expand to wood, steel, concrete, ICF, and SIP. `Builders::Roof::Builder` reserves the stable roof assembly boundary for the next milestone.

`RegenerationService` dispatches stored assemblies by builder and object type. Builder-specific handlers reconstruct child geometry from the parent's stored parameters while retaining the parent object's stable identity.

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

## Commercial information and delivery

`InformationService` walks the model once and creates normalized takeoff, schedule, material,
validation, coordination, and classification datasets from stored assembly metadata. Reports are
read-only and do not alter model geometry. `ExportService` converts the same report into CSV files,
an Excel-compatible SpreadsheetML workbook, and a JSON assembly summary so exported totals remain
consistent across estimating, BuilderTrend import preparation, procurement, and coordination.

Each builder will register a descriptor and factory with `Core::ModuleRegistry`. The core application consumes the registry and does not require edits for every new module.

SketchUp model changes must run inside an operation so native Undo/Redo remains reliable. Geometry code must accept explicit inputs, return structured results, and keep metadata writes separate from mesh creation where practical.

SQLite will be introduced only after its SketchUp-compatible adapter and packaging strategy are validated. The connection boundary already prevents persistence details from leaking into builders.
