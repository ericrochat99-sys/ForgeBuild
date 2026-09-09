# frozen_string_literal: true

module ForgeBuild
  module Builders
    module Wall
      module Catalog
        SYSTEMS = {
          cmu_wall: [:line, 'CMU Wall', 'Standard, lightweight, architectural, acoustical, or glazed CMU wall.', 8, 120, '04 22 00'],
          reinforced_cmu: [:line, 'Reinforced CMU Wall', 'CMU wall with grouted cells, jamb bars, dowels, and bond beams.', 8, 144, '04 22 00'],
          brick_wall: [:line, 'Structural Brick Wall', 'Multi-wythe structural clay masonry wall.', 8, 120, '04 21 13'],
          concrete_wall: [:line, 'Concrete Wall', 'Cast-in-place concrete foundation, retaining, or shear wall.', 10, 120, '03 30 00'],
          metal_stud_wall: [:line, 'Metal-Stud Wall', 'Cold-formed commercial metal-stud partition or exterior wall.', 6, 120, '09 22 16'],
          shaft_wall: [:line, 'Shaft Wall', 'Rated shaft-wall system.', 4, 120, '09 21 16'],
          chase_wall: [:line, 'Chase Wall', 'Double-framed plumbing or mechanical chase wall.', 12, 120, '09 22 16'],
          pony_wall: [:line, 'Pony Wall', 'Partial-height framed wall.', 6, 42, '09 22 16'],
          furred_wall: [:line, 'Furred Wall', 'Furring and liner assembly at an existing substrate.', 2.5, 120, '09 22 16'],
          structural_stud_wall: [:line, 'Structural Steel-Stud Wall', 'Load-bearing light-gauge exterior wall framing.', 8, 144, '05 40 00'],
          wood_wall: [:line, 'Wood-Framed Wall', 'Limited-use or Type V wood-framed wall.', 5.5, 96, '06 10 00'],
          insulated_metal_panel: [:line, 'Insulated Metal Panel', 'Insulated metal wall-panel system.', 4, 144, '07 42 13'],
          tilt_up_panel: [:line, 'Tilt-Up Concrete Panel', 'Site-cast tilt-up wall panel.', 8, 240, '03 47 13'],
          precast_panel: [:line, 'Precast Wall Panel', 'Architectural or structural precast concrete panel.', 8, 240, '03 45 00'],
          icf_wall: [:line, 'ICF Wall', 'Insulating concrete form wall.', 12, 120, '03 11 19'],
          sip_wall: [:line, 'SIP Wall', 'Structural insulated panel wall.', 6.5, 120, '06 12 00'],
          storefront_placeholder: [:line, 'Storefront Placeholder', 'Manufacturer-ready storefront opening zone.', 4.5, 120, '08 41 13'],
          curtain_wall_placeholder: [:line, 'Curtain Wall Placeholder', 'Manufacturer-ready curtain-wall zone.', 6, 144, '08 44 13'],
          glazed_partition: [:line, 'Glazed Partition', 'Interior glazed partition placeholder.', 4, 108, '10 22 39'],
          exterior_sheathing: [:layer, 'Exterior Sheathing', 'Exterior gypsum, cementitious, or structural sheathing layer.', 0.625, 120, '06 16 00'],
          air_barrier: [:layer, 'Air / Weather Barrier', 'Air barrier or water-resistive barrier layer.', 0.05, 120, '07 27 00'],
          continuous_insulation: [:layer, 'Continuous Insulation', 'Continuous exterior insulation layer.', 2, 120, '07 21 00'],
          rainscreen: [:layer, 'Rainscreen Cavity', 'Ventilated rainscreen cavity and attachment zone.', 1, 120, '07 42 00'],
          vapor_retarder: [:layer, 'Vapor Retarder', 'Wall vapor-retarder layer.', 0.04, 120, '07 26 00'],
          brick_veneer: [:layer, 'Brick Veneer', 'Anchored brick veneer layer.', 4, 120, '04 21 13'],
          stone_veneer: [:layer, 'Stone Veneer', 'Anchored or adhered stone veneer layer.', 4, 120, '04 43 00'],
          metal_panel: [:layer, 'Metal Wall Panel', 'Concealed or exposed-fastener metal panel cladding.', 1.5, 144, '07 42 13'],
          fiber_cement: [:layer, 'Fiber-Cement Cladding', 'Fiber-cement panel or siding layer.', 0.5, 120, '07 46 46'],
          eifs: [:layer, 'EIFS', 'Exterior insulation and finish system.', 3, 120, '07 24 00'],
          stucco: [:layer, 'Stucco', 'Portland-cement plaster wall finish.', 0.875, 120, '09 24 00'],
          gypsum_board: [:layer, 'Gypsum Board', 'Interior gypsum board layer.', 0.625, 120, '09 29 00'],
          abuse_resistant_board: [:layer, 'Abuse-Resistant Board', 'Impact or abuse-resistant interior board.', 0.625, 120, '09 29 00'],
          cement_board: [:layer, 'Cement / Tile Backer', 'Cementitious tile-backer layer.', 0.5, 120, '09 28 00'],
          acoustical_panel: [:layer, 'Acoustical Wall Panel', 'Acoustical or impact-resistant wall panel layer.', 1, 96, '09 84 00'],
          door_opening: [:opening, 'Door / HM Frame Opening', 'Door and hollow-metal-frame opening.', 36, 84, '08 11 13'],
          borrowed_lite: [:opening, 'Borrowed Lite', 'Interior borrowed-lite opening.', 48, 48, '08 11 13'],
          storefront_opening: [:opening, 'Storefront Opening', 'Storefront rough-opening placeholder.', 120, 96, '08 41 13'],
          window_opening: [:opening, 'Window Opening', 'Window rough opening.', 48, 48, '08 50 00'],
          louver_opening: [:opening, 'Louver Opening', 'Mechanical louver rough opening.', 48, 48, '08 91 00'],
          access_panel: [:opening, 'Access Panel', 'Wall access-panel opening.', 24, 24, '08 31 00'],
          overhead_door: [:opening, 'Overhead Door Opening', 'Sectional or rolling overhead-door opening.', 144, 144, '08 36 00'],
          lintel: [:line, 'Lintel / Header', 'Masonry, steel, or framed opening lintel.', 8, 8, '04 05 19'],
          sill: [:line, 'Sill / Base Angle', 'Opening sill, base angle, or support plate.', 6, 4, '05 50 00'],
          bond_beam: [:line, 'Bond Beam', 'Reinforced masonry bond beam.', 8, 8, '04 22 00'],
          grouted_cells: [:line, 'Grouted Cells', 'Grouted masonry cell layout and quantity zone.', 8, 120, '04 05 16'],
          reinforcing: [:line, 'Wall Reinforcing', 'Masonry jamb bars, dowels, horizontal reinforcing, and anchors.', 0.625, 120, '04 05 19'],
          control_joint: [:point, 'Wall Control Joint', 'Vertical masonry or panel movement joint.', 0.5, 120, '04 05 23'],
          pilaster: [:point, 'Pilaster / Wall Pier', 'Reinforced masonry or concrete pilaster.', 16, 120, '04 22 00'],
          embed_plate: [:point, 'Embed / Anchor Plate', 'Embed, bearing plate, anchor, or connection object.', 8, 8, '05 05 19'],
          head_joint: [:line, 'Head-of-Wall Joint', 'Rated or non-rated head-of-wall joint.', 1, 1, '07 84 43'],
          base_joint: [:line, 'Base-of-Wall Joint', 'Rated or acoustical base-of-wall joint.', 1, 1, '07 84 43']
        }.freeze
        module_function
        def definition(id) = SYSTEMS.fetch(id.to_sym)
      end
    end
  end
end
