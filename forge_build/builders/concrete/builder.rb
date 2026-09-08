# frozen_string_literal: true

module ForgeBuild
  module Builders
    module Concrete
      class Builder < Core::Builder
        TOOLS = [
          Tool.new(id: :slab_on_grade, name: 'Slab on Grade', description: 'Place a parametric rectangular slab.'),
          Tool.new(id: :equipment_pad, name: 'Equipment Pad', description: 'Place a parametric housekeeping pad.')
        ].freeze

        def id = :concrete
        def name = 'Concrete Builder'
        def division = '03'
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
