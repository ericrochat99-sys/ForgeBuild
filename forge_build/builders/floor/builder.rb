# frozen_string_literal: true

module ForgeBuild
  module Builders
    module Floor
      # Creates complete horizontal building assemblies. Concrete slabs are the
      # first production vertical slice; framed systems plug into this builder.
      class Builder < Core::Builder
        THICKNESS = lambda do |value|
          [{ id: 'thickness', label: 'Thickness', type: 'number', value: value,
             min: 0.125, step: 0.125, unit: 'inches' }]
        end

        TOOLS = [
          Tool.new(id: :slab_on_grade, name: 'Slab on Grade',
                   description: 'Place a parametric rectangular floor slab.', options: THICKNESS.call(6)),
          Tool.new(id: :equipment_pad, name: 'Equipment Pad',
                   description: 'Place a parametric housekeeping pad.', options: THICKNESS.call(4))
        ].freeze

        def id = :floor
        def name = 'Floor Builder'
        def divisions = %w[03 05 06].freeze
        def tools = TOOLS

        def activate_tool(id, options = {})
          selected = tool(id)
          default = selected.id == :equipment_pad ? 4.0 : 6.0
          thickness = Float(options.fetch('thickness', default))
          raise ArgumentError, 'Thickness must be greater than zero' unless thickness.positive?

          Sketchup.active_model.select_tool(
            Tools::ConcreteRectangleTool.new(service: container.resolve(:concrete_objects),
                                             object_type: selected.id.to_s, thickness: thickness)
          )
        end
      end
    end
  end
end
