# frozen_string_literal: true
require_relative 'catalog'
module ForgeBuild
  module Builders
    module Roof
      class Builder < Core::Builder
        TOOLS = Catalog::SYSTEMS.map do |id, (kind, label, description, size, pitch_or_height, _cost_code)|
          options = if %i[area layer].include?(kind)
                      [{ id: 'thickness', label: 'Thickness', type: 'number', value: size, min: 0.01, step: 0.125, unit: 'inches' },
                       { id: 'pitch', label: 'Pitch', type: 'number', value: pitch_or_height, min: 0, step: 0.25, unit: 'inches per foot' },
                       { id: 'elevation', label: 'Elevation offset', type: 'number', value: 0, step: 1, unit: 'inches' },
                       { id: 'seam_spacing', label: 'Seam / flute spacing', type: 'number', value: %i[steel_roof_deck standing_seam exposed_fastener].include?(id) ? 12 : 0, min: 0, step: 1, unit: 'inches' },
                       { id: 'overhang', label: 'Overhang', type: 'number', value: 0, min: 0, step: 1, unit: 'inches' }]
                    elsif kind == :line
                      [{ id: 'width', label: 'Width', type: 'number', value: size, min: 0.01, step: 0.125, unit: 'inches' },
                       { id: 'height', label: 'Height / depth', type: 'number', value: pitch_or_height, min: 0.01, step: 0.125, unit: 'inches' },
                       { id: 'spacing', label: 'Member spacing', type: 'number', value: 0, min: 0, step: 1, unit: 'inches o.c.' }]
                    else
                      [{ id: 'width', label: 'Width', type: 'number', value: size, min: 0.01, step: 1, unit: 'inches' },
                       { id: 'depth', label: 'Depth', type: 'number', value: size, min: 0.01, step: 1, unit: 'inches' },
                       { id: 'height', label: 'Height', type: 'number', value: pitch_or_height, min: 0.01, step: 1, unit: 'inches' },
                       { id: 'elevation', label: 'Elevation offset', type: 'number', value: 0, step: 1, unit: 'inches' }]
                    end
          Tool.new(id: id, name: label, description: description, options: options)
        end.freeze
        def id = :roof
        def name = 'Roof Builder'
        def divisions = %w[03 05 06 07 08 10 22].freeze
        def tools = TOOLS
        def activate_tool(id, options = {})
          selected = tool(id)
          kind = Catalog.definition(selected.id).first
          normalized = options.each_with_object({}) { |(key, value), result| result[key.to_sym] = Float(value) }
          Sketchup.active_model.select_tool(Tools::RoofPlacementTool.new(service: container.resolve(:roof_objects),
            object_type: selected.id.to_s, kind: kind, options: normalized))
        end
      end
    end
  end
end
