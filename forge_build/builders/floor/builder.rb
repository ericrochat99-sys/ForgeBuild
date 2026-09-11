# frozen_string_literal: true

require_relative 'catalog'

module ForgeBuild
  module Builders
    module Floor
      class Builder < Core::Builder
        STRING_OPTIONS = %w[notes placement_shape snap_to_angle snap_to_distance snap_alignment].freeze

        TOOLS = Catalog::SYSTEMS.map do |id, (kind, label, description, size, height)|
          options = case kind
                    when :area
                      [{ id: 'thickness', label: 'Thickness / depth', type: 'number', value: size, min: 0.01, step: 0.125, unit: 'inches' },
                       { id: 'elevation', label: 'Elevation offset', type: 'number', value: height, step: 1, unit: 'inches' },
                       { id: 'slope', label: 'Slope', type: 'number', value: 0, min: 0, step: 0.125, unit: '%' }]
                    when :linear
                      [{ id: 'width', label: 'Width', type: 'number', value: size, min: 0.01, step: 0.125, unit: 'inches' },
                       { id: 'height', label: 'Height / depth', type: 'number', value: height, min: 0.01, step: 0.125, unit: 'inches' },
                       { id: 'spacing', label: 'Spacing', type: 'number', value: 0, min: 0, step: 1, unit: 'inches o.c.' }]
                    when :point
                      [{ id: 'width', label: 'Width', type: 'number', value: size, min: 0.01, step: 0.125, unit: 'inches' },
                       { id: 'length', label: 'Length', type: 'number', value: size, min: 0.01, step: 0.125, unit: 'inches' },
                       { id: 'height', label: 'Height / depth', type: 'number', value: height, min: 0.01, step: 0.125, unit: 'inches' }]
                    else
                      [{ id: 'thickness', label: 'Thickness', type: 'number', value: size, min: 0.01, step: 0.125, unit: 'inches' }]
                    end
          options += case id
                     when :slab_on_grade
                       [{ id: 'edge_width', label: 'Thickened edge width', type: 'number', value: 0, min: 0, step: 1, unit: 'inches' },
                        { id: 'edge_depth', label: 'Turndown depth', type: 'number', value: 0, min: 0, step: 1, unit: 'inches' },
                        { id: 'depression_depth', label: 'Depression depth', type: 'number', value: 0, min: 0, step: 0.125, unit: 'inches' }]
                     when :metal_deck
                       [{ id: 'span', label: 'Deck span', type: 'number', value: 120, min: 1, step: 1, unit: 'inches' },
                        { id: 'direction', label: 'Deck direction', type: 'number', value: 0, min: 0, step: 1, unit: 'degrees' },
                        { id: 'flute_spacing', label: 'Flute spacing', type: 'number', value: 6, min: 1, step: 0.5, unit: 'inches' }]
                     when :steel_joist, :floor_truss, :wood_joist
                       [{ id: 'bearing_length', label: 'Bearing / seat length', type: 'number', value: 4, min: 0, step: 0.5, unit: 'inches' }]
                     else []
                     end
          Tool.new(id: id, name: label, description: description, options: options)
        end.freeze

        def id = :floor
        def name = 'Floor Builder'
        def divisions = %w[03 05 06].freeze
        def tools = TOOLS

        def activate_tool(id, options = {})
          selected = tool(id)
          kind = Catalog.definition(selected.id).first
          normalized = options.each_with_object({}) do |(key, value), result|
            result[key.to_sym] = STRING_OPTIONS.include?(key.to_s) ? value.to_s : Float(value)
          end
          if kind == :face
            face = Sketchup.active_model.selection.find { |entity| entity.is_a?(Sketchup::Face) }
            raise ArgumentError, 'Select a horizontal face or traced boundary first' unless face
            container.resolve(:floor_objects).create_from_face(model: Sketchup.active_model, face: face,
                                                                object_type: selected.id.to_s,
                                                                thickness: normalized.fetch(:thickness, 6.0))
            return
          end
          Sketchup.active_model.select_tool(
            Tools::FloorPlacementTool.new(service: container.resolve(:floor_objects), object_type: selected.id.to_s,
                                          kind: kind, options: normalized)
          )
        end
      end
    end
  end
end
