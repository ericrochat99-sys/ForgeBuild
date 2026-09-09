# frozen_string_literal: true

module ForgeBuild
  module Builders
    module Roof
      module Catalog
        SYSTEMS = {
          low_slope_roof: [:area, 'Low-Slope Roof', 'Flat or low-slope commercial roof boundary.', 6, 0.25, '07 50 00'],
          concrete_roof_deck: [:area, 'Concrete Roof Deck', 'Cast-in-place concrete roof deck.', 6, 0.25, '03 30 00'],
          precast_roof: [:area, 'Precast Roof System', 'Precast concrete roof deck or plank zone.', 8, 0.25, '03 40 00'],
          steel_roof_deck: [:area, 'Steel Roof Deck', 'Steel roof deck profile with span and direction.', 3, 0.25, '05 31 00'],
          tapered_insulation: [:area, 'Tapered Insulation Zone', 'Tapered insulation, cricket, saddle, or sump zone.', 4, 2, '07 22 00'],
          tpo_membrane: [:layer, 'TPO Membrane', 'Thermoplastic polyolefin roof membrane.', 0.08, 0.25, '07 54 23'],
          pvc_membrane: [:layer, 'PVC Membrane', 'PVC roof membrane.', 0.08, 0.25, '07 54 19'],
          epdm_membrane: [:layer, 'EPDM Membrane', 'EPDM roof membrane.', 0.06, 0.25, '07 53 23'],
          modified_bitumen: [:layer, 'Modified-Bitumen Roofing', 'Modified-bitumen roof membrane system.', 0.25, 0.25, '07 52 00'],
          built_up_roof: [:layer, 'Built-Up Roofing', 'Multi-ply built-up roofing system.', 0.5, 0.25, '07 51 00'],
          cover_board: [:layer, 'Cover Board', 'Roof cover-board layer.', 0.5, 0.25, '07 22 00'],
          roof_vapor_retarder: [:layer, 'Roof Vapor Retarder', 'Roof air/vapor-control layer.', 0.04, 0.25, '07 26 00'],
          rigid_insulation: [:layer, 'Rigid Roof Insulation', 'Continuous rigid roof insulation.', 4, 0.25, '07 22 00'],
          protection_layer: [:layer, 'Protection Layer', 'Protection mat or separator layer.', 0.125, 0.25, '07 50 00'],
          ballast: [:layer, 'Roof Ballast', 'Aggregate or paver ballast layer.', 2, 0.25, '07 55 00'],
          gable_roof: [:area, 'Gable Roof', 'Two-plane gable roof assembly.', 8, 4, '07 30 00'],
          hip_roof: [:area, 'Hip Roof', 'Four-plane hip roof assembly.', 8, 4, '07 30 00'],
          shed_roof: [:area, 'Shed / Mono-Slope Roof', 'Single-plane sloped roof assembly.', 8, 3, '07 30 00'],
          multi_plane_roof: [:area, 'Multi-Plane Roof', 'Specialty multi-plane roof zone.', 8, 4, '07 30 00'],
          gymnasium_roof: [:area, 'Gymnasium Long-Span Roof', 'Long-span gymnasium roof assembly zone.', 8, 1, '05 21 00'],
          auditorium_roof: [:area, 'Auditorium Roof', 'Long-span or acoustically coordinated auditorium roof.', 8, 1, '05 21 00'],
          standing_seam: [:layer, 'Standing-Seam Metal Roof', 'Concealed-fastener standing-seam roof panels.', 1.5, 3, '07 41 13'],
          exposed_fastener: [:layer, 'Exposed-Fastener Metal Roof', 'Exposed-fastener metal roof panels.', 1.5, 3, '07 41 13'],
          shingles: [:layer, 'Shingle Roofing', 'Asphalt or specialty shingle roof layer.', 0.5, 4, '07 31 13'],
          roof_tile: [:layer, 'Roof Tile', 'Clay, concrete, or composite roof tile layer.', 1, 4, '07 32 00'],
          roof_panel: [:layer, 'Insulated Roof Panel', 'Insulated or structural roof-panel system.', 4, 3, '07 41 00'],
          steel_beam: [:line, 'Roof Steel Beam', 'Structural steel roof beam or girder.', 8, 16, '05 12 00'],
          steel_joist: [:line, 'Roof Steel Joist', 'Open-web steel roof joist or joist girder.', 4, 24, '05 21 00'],
          bridging: [:line, 'Roof Joist Bridging', 'Horizontal or diagonal joist bridging.', 1, 1, '05 21 00'],
          cold_formed_framing: [:line, 'Cold-Formed Roof Framing', 'Cold-formed roof joist or rafter.', 6, 12, '05 40 00'],
          wood_rafter: [:line, 'Wood Rafter', 'Dimensional or engineered wood rafter.', 2, 12, '06 10 00'],
          timber_member: [:line, 'Timber Roof Member', 'Heavy timber beam or purlin.', 8, 16, '06 13 00'],
          roof_truss: [:line, 'Roof Truss', 'Wood, light-gauge, or structural roof truss.', 4, 36, '06 17 53'],
          purlin: [:line, 'Purlin / Girt', 'Roof purlin or girt.', 6, 8, '05 12 00'],
          ridge_member: [:line, 'Ridge Member', 'Structural ridge beam or ridge board.', 4, 12, '06 10 00'],
          fascia: [:line, 'Fascia', 'Roof fascia assembly.', 1, 10, '06 46 00'],
          eave_overhang: [:line, 'Eave / Overhang', 'Roof eave and overhang assembly.', 24, 8, '06 10 00'],
          soffit: [:line, 'Soffit', 'Exterior soffit or canopy soffit.', 24, 1, '07 77 00'],
          parapet: [:line, 'Parapet', 'Roof parapet wall.', 8, 36, '07 72 00'],
          coping: [:line, 'Coping', 'Metal, stone, or precast parapet coping.', 12, 2, '07 62 00'],
          blocking: [:line, 'Roof Blocking', 'Wood or composite roof-edge blocking.', 6, 6, '06 10 00'],
          cant_strip: [:line, 'Cant Strip', 'Roof-membrane cant strip.', 4, 4, '07 50 00'],
          expansion_joint: [:line, 'Roof Expansion Joint', 'Roof expansion-joint assembly.', 12, 8, '07 95 13'],
          gutter: [:line, 'Gutter', 'Roof gutter or box gutter.', 6, 6, '07 71 23'],
          downspout: [:line, 'Downspout', 'Downspout or conductor run.', 4, 4, '07 71 23'],
          roof_drain: [:point, 'Primary Roof Drain', 'Primary roof drain and sump.', 18, 6, '22 14 26'],
          overflow_drain: [:point, 'Overflow Roof Drain', 'Secondary overflow roof drain.', 18, 6, '22 14 26'],
          scupper: [:point, 'Roof Scupper', 'Primary or overflow wall scupper.', 12, 8, '07 71 00'],
          conductor_head: [:point, 'Conductor Head', 'Leader or conductor head.', 12, 18, '07 71 23'],
          roof_curb: [:point, 'Equipment Curb', 'Roof equipment or duct curb.', 36, 18, '07 72 13'],
          roof_hatch: [:point, 'Roof Hatch', 'Roof hatch and curb opening.', 36, 36, '07 72 33'],
          skylight: [:point, 'Skylight / Clerestory', 'Skylight, smoke vent, or clerestory opening.', 48, 12, '08 62 00'],
          smoke_vent: [:point, 'Smoke Vent', 'Automatic smoke-vent opening.', 48, 12, '08 63 00'],
          roof_penetration: [:point, 'Roof Penetration', 'Duct, pipe, or equipment penetration.', 12, 12, '07 72 00'],
          roof_opening: [:point, 'Roof Opening', 'Framed roof opening for equipment or access.', 48, 12, '05 31 00'],
          canopy: [:area, 'Canopy / Covered Walkway', 'Entrance canopy or covered-walkway roof.', 6, 2, '10 73 00']
        }.freeze
        module_function
        def definition(id) = SYSTEMS.fetch(id.to_sym)
      end
    end
  end
end
