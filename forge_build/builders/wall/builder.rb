# frozen_string_literal: true

module ForgeBuild
  module Builders
    module Wall
      # Owns structural wall systems and their finishes, openings, and reinforcing.
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
          [:cmu_wall, 'CMU Wall', 'Draw a parametric CMU wall assembly.'],
          [:brick_wall, 'Brick Wall', 'Draw a full-depth structural brick wall.'],
          [:brick_veneer, 'Brick Veneer', 'Draw a brick wall finish layer.'],
          [:stone_veneer, 'Stone Veneer', 'Draw a stone wall finish layer.'],
          [:pilaster, 'Pilaster', 'Place a reinforced masonry pilaster.'],
          [:control_joint, 'Control Joint', 'Place a vertical masonry movement joint.'],
          [:lintel, 'Lintel', 'Draw a masonry or steel lintel.'],
          [:bond_beam, 'Bond Beam', 'Draw a reinforced masonry bond beam.'],
          [:grouted_cells, 'Grouted Cells', 'Lay out grouted cells along a wall run.'],
          [:reinforcing, 'Reinforcing', 'Lay out masonry reinforcement.']
        ].map { |type, label, description|
          Tool.new(id: type, name: label, description: description, options: options(type))
        }.freeze

        def id = :wall
        def name = 'Wall Builder'
        def divisions = %w[03 04 05 06 07 09].freeze
        def tools = TOOLS

        def activate_tool(id, options = {})
          selected = tool(id)
          defaults = TYPE_DEFAULTS.fetch(selected.id)
          Sketchup.active_model.select_tool(
            Tools::MasonryLineTool.new(service: container.resolve(:masonry_objects),
                                       object_type: selected.id.to_s,
                                       thickness: positive_number(options, 'thickness', defaults[0]),
                                       height: positive_number(options, 'height', defaults[1]),
                                       cell_spacing: positive_number(options, 'cell_spacing', 48))
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
