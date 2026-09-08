# frozen_string_literal: true

module ForgeBuild
  module Builders
    module Masonry
      class Builder < Core::Builder
        TYPE_DEFAULTS = {
          cmu_wall: [8, 96], brick_wall: [8, 96], brick_veneer: [4, 96],
          stone_veneer: [4, 96], pilaster: [16, 96], control_joint: [0.375, 96],
          lintel: [8, 8], bond_beam: [8, 8], grouted_cells: [8, 96], reinforcing: [0.625, 96]
        }.freeze

        def self.options(type)
          thickness, height = TYPE_DEFAULTS.fetch(type)
          fields = [
            { id: 'thickness', label: 'Nominal thickness', type: 'number', value: thickness,
              min: 0.125, step: 0.125, unit: 'inches' },
            { id: 'height', label: 'Height', type: 'number', value: height,
              min: 0.125, step: 0.125, unit: 'inches' }
          ]
          if %i[cmu_wall brick_wall bond_beam grouted_cells reinforcing pilaster].include?(type)
            fields << { id: 'cell_spacing', label: 'Reinforcing spacing', type: 'number',
                        value: 48, min: 8, step: 8, unit: 'inches o.c.' }
          end
          fields
        end

        TOOLS = [
          [:cmu_wall, 'CMU Wall', 'Draw a parametric concrete masonry unit wall.'],
          [:brick_wall, 'Brick Wall', 'Draw a full-depth structural brick wall.'],
          [:brick_veneer, 'Brick Veneer', 'Draw a nonstructural brick veneer assembly.'],
          [:stone_veneer, 'Stone Veneer', 'Draw a manufactured or natural stone veneer.'],
          [:pilaster, 'Pilaster', 'Place a reinforced masonry pilaster.'],
          [:control_joint, 'Control Joint', 'Place a vertical masonry movement joint.'],
          [:lintel, 'Lintel', 'Draw a masonry or steel lintel over an opening.'],
          [:bond_beam, 'Bond Beam', 'Draw a horizontal reinforced masonry bond beam.'],
          [:grouted_cells, 'Grouted Cells', 'Lay out grouted masonry cells along a wall run.'],
          [:reinforcing, 'Reinforcing', 'Lay out Division 04 masonry reinforcement.']
        ].map { |type, name, description|
          Tool.new(id: type, name: name, description: description, options: options(type))
        }.freeze

        def id = :masonry
        def name = 'Masonry Builder'
        def division = '04'
        def tools = TOOLS

        def activate_tool(id, options = {})
          selected = tool(id)
          defaults = TYPE_DEFAULTS.fetch(selected.id)
          thickness = positive_number(options, 'thickness', defaults[0])
          height = positive_number(options, 'height', defaults[1])
          cell_spacing = positive_number(options, 'cell_spacing', 48)

          Sketchup.active_model.select_tool(
            Tools::MasonryLineTool.new(service: container.resolve(:masonry_objects),
                                       object_type: selected.id.to_s, thickness: thickness,
                                       height: height, cell_spacing: cell_spacing)
          )
        end

        private

        def positive_number(options, key, default)
          value = Float(options.fetch(key, default))
          raise ArgumentError, "#{key.tr('_', ' ').capitalize} must be greater than zero" unless value.positive?

          value
        end
      end
    end
  end
end
