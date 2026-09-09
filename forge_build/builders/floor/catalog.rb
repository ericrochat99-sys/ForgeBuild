# frozen_string_literal: true

module ForgeBuild
  module Builders
    module Floor
      module Catalog
        SYSTEMS = {
          slab_on_grade: [:area, 'Slab on Grade', 'Concrete slab with configurable edge, recess, slope, and depression data.', 6, 0],
          slab_recess: [:area, 'Slab Recess / Depression', 'Recessed or depressed slab coordination zone.', 2, -2],
          elevated_slab: [:area, 'Elevated Concrete Slab', 'Elevated cast-in-place structural slab.', 8, 120],
          composite_slab: [:area, 'Composite Slab on Deck', 'Concrete slab over composite metal deck.', 6.5, 120],
          noncomposite_slab: [:area, 'Slab on Form Deck', 'Concrete slab over non-composite form deck.', 5, 120],
          vapor_retarder: [:area, 'Vapor Retarder', 'Underslab vapor-retarder layer.', 0.04, -0.04],
          underslab_insulation: [:area, 'Underslab Insulation', 'Continuous rigid underslab insulation.', 2, -2],
          granular_base: [:area, 'Granular Base', 'Compacted granular base layer.', 6, -6],
          prepared_subgrade: [:area, 'Prepared Subgrade', 'Prepared and compacted subgrade zone.', 12, -18],
          metal_deck: [:area, 'Metal Floor Deck', 'Composite or form deck zone with span and direction metadata.', 3, 117],
          hollow_core: [:area, 'Hollow-Core Plank', 'Precast hollow-core floor member zone.', 8, 120],
          precast_member: [:linear, 'Precast Floor Member', 'Precast concrete beam or floor member.', 12, 24],
          steel_framing_zone: [:area, 'Steel Floor Framing Zone', 'Composite or non-composite steel framing layout zone.', 1, 120],
          thickened_edge: [:linear, 'Thickened Slab Edge', 'Thickened slab perimeter or turndown.', 18, 18],
          continuous_footing: [:linear, 'Continuous Footing', 'Continuous strip footing.', 24, 12],
          grade_beam: [:linear, 'Grade Beam', 'Reinforced concrete grade beam.', 16, 24],
          foundation_wall: [:linear, 'Foundation Wall', 'Cast-in-place foundation wall.', 12, 96],
          construction_joint: [:linear, 'Construction Joint', 'Concrete construction joint.', 0.25, 6],
          control_joint: [:linear, 'Control Joint', 'Sawcut or tooled slab control joint.', 0.125, 1.5],
          isolation_joint: [:linear, 'Isolation Joint', 'Isolation joint at vertical construction.', 0.5, 6],
          pour_strip: [:linear, 'Pour Strip', 'Delayed concrete pour strip.', 36, 6],
          expansion_joint: [:linear, 'Expansion Joint', 'Full-depth expansion joint.', 2, 6],
          trench: [:linear, 'Floor Trench', 'Trench or trench-drain zone.', 12, 12],
          steel_beam: [:linear, 'Steel Beam', 'Structural steel beam or girder.', 8, 16],
          steel_joist: [:linear, 'Open-Web Steel Joist', 'Open-web joist or joist-girder run.', 4, 24],
          bridging: [:linear, 'Joist Bridging', 'Joist bridging run.', 1, 1],
          wood_joist: [:linear, 'Wood Joist', 'Sawn or engineered wood joist.', 2, 12],
          floor_truss: [:linear, 'Wood Floor Truss', 'Light-commercial wood floor truss.', 4, 18],
          pour_stop: [:linear, 'Pour Stop / Edge Angle', 'Pour stop, bent plate, edge angle, or deck closure.', 0.25, 6],
          deck_closure: [:linear, 'Deck Closure', 'Metal deck end, side, or flute closure.', 2, 3],
          beam_pocket: [:point, 'Beam Pocket / Bearing', 'Beam pocket, joist seat, bearing, or support condition.', 12, 12],
          coordination_zone: [:linear, 'MEP Coordination Zone', 'Reserved coordination zone for building systems.', 24, 24],
          spread_footing: [:point, 'Spread Footing', 'Isolated spread footing.', 48, 12],
          pier: [:point, 'Concrete Pier', 'Concrete pier or pedestal.', 24, 36],
          equipment_pad: [:point, 'Equipment Pad', 'Housekeeping pad or equipment foundation.', 36, 4],
          floor_drain: [:point, 'Floor Drain', 'Floor drain coordination object.', 8, 2],
          pit: [:point, 'Pit / Sump', 'Equipment pit or sump.', 48, 48],
          column: [:point, 'Column / Post', 'Column, post, or bearing point.', 12, 120],
          sleeve: [:point, 'Sleeve / Penetration', 'Sleeve, blockout, curb, or penetration.', 8, 8],
          rectangular_opening: [:area, 'Rectangular Opening', 'Rectangular floor, shaft, stair, elevator, or equipment opening.', 6, 0],
          circular_opening: [:point, 'Circular Opening', 'Circular penetration or core opening coordination object.', 8, 6],
          polygon_opening: [:area, 'Polygon / Shaft Opening', 'Polygonal, shaft, stair, elevator, or equipment opening zone.', 6, 0],
          blockout: [:point, 'Blockout / Curb', 'Concrete blockout, equipment curb, or framed penetration.', 12, 6],
          opening_reinforcement: [:linear, 'Opening Reinforcement', 'Framed opening reinforcement or slab-edge strengthening.', 4, 8],
          reinforcing_zone: [:area, 'Slab Reinforcing', 'WWR, reinforcing bars, dowels, embeds, or edge reinforcement zone.', 0.625, 1.5],
          floor_from_face: [:face, 'Floor From Selected Face', 'Generate a rectangular or polygonal floor from a selected face or traced boundary.', 6, 0]
        }.freeze

        module_function
        def definition(id) = SYSTEMS.fetch(id.to_sym)
      end
    end
  end
end
