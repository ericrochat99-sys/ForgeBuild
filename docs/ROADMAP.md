# ForgeBuild Roadmap

ForgeBuild is focused on construction methods commonly used for K-12 schools, higher-education facilities, municipal buildings, healthcare, offices, retail, warehouses, gymnasiums, and other commercial or institutional projects.

CSI divisions and cost codes remain attached to model components for estimating. The modeling workflow is organized around complete Floor, Wall, and Roof assemblies.

## Phase 1 — Commercial assembly platform

- Selection-driven Property Inspector.
- Edit, move, copy, delete, and regenerate assembly commands.
- Right-click context menus for ForgeBuild objects.
- Parent/child assembly relationships and stable object identifiers.
- Schematic 2D, simplified 3D, and detailed 3D display modes.
- Saved project, system, and assembly presets with practical commercial defaults.
- SketchUp tag, material, visibility, and scene management.
- SQLite project and preset storage after adapter compatibility is validated.
- Migration support for objects created by earlier ForgeBuild versions.
- Diagnostics, operation safety, CI, semantic versioning, and repeatable RBZ releases.

## Phase 2 — Floor Builder

### Concrete floor and foundation systems

- Slab-on-grade with thickened edges, turndowns, recesses, slopes, and depressions.
- Elevated cast-in-place concrete slabs.
- Concrete slab over composite or non-composite metal deck.
- Foundations associated with floors: spread footings, continuous footings, grade beams, foundation walls, piers, and equipment pads.
- Vapor retarders, underslab insulation, granular base, and prepared subgrade layers.
- Construction joints, control joints, isolation joints, pour strips, and expansion joints.
- Welded-wire reinforcement, reinforcing bars, dowels, embeds, and edge reinforcing.
- Floor drains, trenches, housekeeping pads, pits, sumps, and equipment foundations.

### Structural floor systems

- Structural steel beams and girders.
- Composite and non-composite steel floor framing.
- Open-web steel joists, joist girders, bridging, seats, and bearing conditions.
- Composite and form metal deck profiles with direction, span, sidelaps, and closures.
- Precast hollow-core planks and precast concrete floor members.
- Wood joists, engineered I-joists, and wood floor trusses for limited school or light-commercial applications.
- Columns, posts, bearing points, beam pockets, and supporting conditions.
- Slab edges, pour stops, bent plates, edge angles, and deck closures.

### Floor openings and coordination

- Rectangular, circular, polygonal, shaft, stair, elevator, and equipment openings.
- Sleeves, blockouts, curbs, penetrations, and framed opening reinforcement.
- Coordination zones for plumbing, HVAC, electrical, fire protection, and structural systems.
- Floor perimeter editing, edge movement, opening relocation, and full regeneration.
- Floor plans generated from rectangles, polygons, selected faces, or traced boundaries.

## Phase 3 — Wall Builder

### Commercial wall systems

- Concrete masonry walls using standard, lightweight, architectural, acoustical, and glazed CMU.
- Reinforced CMU with grouted cells, bond beams, lintels, jamb bars, dowels, and control joints.
- Cast-in-place concrete walls, foundation walls, retaining walls, and shear walls.
- Cold-formed metal-stud walls, shaft walls, chase walls, pony walls, and furred walls.
- Structural steel stud and light-gauge exterior wall framing.
- Wood-framed walls for limited-use, accessory, or Type V construction.
- Insulated metal panels, tilt-up concrete panels, precast wall panels, ICF, and SIP systems.
- Storefront, curtain-wall, and glazed-partition placeholders with manufacturer-ready opening dimensions.

### Wall layers and rated construction

- Exterior sheathing, air barriers, weather barriers, continuous insulation, rainscreens, and vapor retarders.
- Brick veneer, stone veneer, metal panels, fiber-cement panels, EIFS, stucco, and other commercial cladding.
- Interior gypsum board, abuse-resistant board, cement board, tile backer, acoustical panels, and impact-resistant layers.
- Fire-resistance, smoke, acoustical, thermal, and security properties stored with each assembly.
- UL/GA design references and rated head-of-wall, base-of-wall, joint, and penetration metadata.
- Wall priorities and layer intersections at corners and adjoining assemblies.

### Openings and accessories

- Doors, hollow-metal frames, borrowed lites, storefront openings, windows, louvers, access panels, and overhead doors.
- Masonry and steel lintels, headers, jambs, sills, embeds, plates, anchors, and reinforcing.
- Automatic corners, tees, intersections, end conditions, pilasters, and wall returns.
- Split, join, stretch, offset, copy, align, connect, and renumber wall commands.
- Opening move, edit, copy, delete, and schedule commands.
- Gable, stepped, sloped, parapet, and partial-height wall profiles.

## Phase 4 — Roof Builder

### Low-slope commercial roofs

- Flat and low-slope roof boundaries with crickets, saddles, sumps, and tapered-insulation zones.
- Structural steel beams, open-web steel joists, joist girders, bridging, and bearing conditions.
- Steel roof deck profiles, direction, span, sidelaps, closures, and edge conditions.
- Concrete roof decks and precast roof systems.
- Roof membranes including TPO, PVC, EPDM, modified-bitumen, and built-up roofing.
- Cover boards, vapor retarders, rigid insulation, tapered insulation, protection layers, and ballast.
- Parapets, coping, blocking, cant strips, curbs, roof hatches, and expansion joints.
- Primary and overflow roof drains, scuppers, gutters, downspouts, and conductor heads.

### Sloped and specialty roofs

- Gable, hip, shed, mono-slope, and multi-plane roof assemblies.
- Structural steel, cold-formed steel, dimensional-lumber, timber, and engineered-wood framing.
- Standing-seam metal, exposed-fastener metal, shingles, tiles, and roof-panel systems.
- Rafters, trusses, purlins, girts, ridge members, fascia, soffits, eaves, and overhangs.
- Gymnasium, auditorium, canopy, covered-walkway, and entrance roof systems.
- Skylights, smoke vents, clerestories, equipment curbs, ducts, piping, and roof penetrations.
- Roof-plane editing, perimeter-edge movement, connection tools, and full regeneration.

## Phase 5 — Commercial information and delivery

- Quantity takeoff by assembly, material, CSI division, cost code, level, area, and building.
- Concrete, reinforcing, masonry, steel, decking, framing, insulation, sheathing, cladding, roofing, and finish quantities.
- Opening, door, window, louver, beam, joist, column, wall, slab, and roof schedules.
- Material lists, waste factors, alternates, allowances, and bid-package exports.
- CSV and Excel exports suitable for estimating and BuilderTrend workflows.
- Assembly summaries for scope review, subcontractor coordination, and procurement.
- Fire-rating, acoustic, thermal, and accessibility validation reports.
- Clash-warning and missing-information reports.
- IFC/DWG interchange and consistent classification metadata.
- Updater hardening, extension signing, licensing, and commercial distribution.

## Phase 6 — Drawing-assisted modeling

- Import, scale, calibrate, rotate, and align architectural, structural, and MEP PDFs.
- Manual tracing tools for floor boundaries, walls, roof perimeters, openings, grids, and levels.
- Drawing revisions, overlay comparison, and addendum tracking.
- Assisted recognition of closed rooms, walls, openings, column grids, slab edges, and roof outlines.
- OCR for dimensions, elevations, room names, wall types, detail references, and assembly tags.
- Suggested commercial assemblies based on drawing annotations, with required user confirmation.
- Model-to-drawing comparison and unresolved-condition reporting.

## Delivery order

1. Property Inspector, editing, presets, and working regeneration handlers.
2. Polygon slab-on-grade, floor openings, footings, grade beams, and foundation walls.
3. Structural steel beams, open-web steel joists, and metal floor deck.
4. Complete reinforced CMU wall assemblies and commercial metal-stud partitions.
5. Door, window, louver, storefront, and overhead-door openings.
6. Low-slope steel-joist and metal-deck commercial roof assemblies.
7. Roof insulation, membrane, parapet, curb, and drainage systems.
8. Quantity takeoff, schedules, and estimating exports.
9. Drawing calibration and assisted tracing.

Every milestone should include automated tests, migration notes, documentation, changelog entries, and a downloadable semantic-versioned RBZ release.

## Current delivery

- Phase 1 complete: shared builder framework, Property Inspector, lifecycle commands, display modes, presets, SQLite schema, materials/tags, and migrations.
- Phase 2 complete: concrete and foundation floors, structural framing, deck and precast systems, openings, coordination objects, selected-face/polygon generation, editing, and regeneration.
- Phase 3 complete: commercial wall systems, finish layers, rated properties, openings, accessories, profiles, editing, and schedules.
- Phase 4 complete: low-slope and specialty roofs, framing, layers, openings, edge assemblies, drainage, editing, and schedules.
- Phase 5 complete: commercial takeoff, schedules, material and bid-package data, validation, coordination warnings, and estimating/interchange exports.
- Phase 6 complete: drawing import/registration, calibration, tracing, revisions, annotation recognition, confirmation-gated suggestions, and model comparison.
- Next: production hardening, field validation, expanded interoperability, and the v1.0 release candidate.
