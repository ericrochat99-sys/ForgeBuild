# frozen_string_literal: true
require_relative 'catalog'
module ForgeBuild
  module Builders
    module Wall
      class Builder < Core::Builder
        STRING_OPTIONS = %w[fire_rating smoke_rating ul_design ga_design security_class notes insulation framing sheathing finish material].freeze
        TOOLS = Catalog::SYSTEMS.map do |id, (kind, label, description, width, height, _cost_code)|
          options = if %i[line layer].include?(kind)
                      [{ id: 'thickness', label: 'Thickness', type: 'number', value: width, min: 0.01, step: 0.125, unit: 'inches' },
                       { id: 'height', label: 'Start height', type: 'number', value: height, min: 0.01, step: 1, unit: 'inches' },
                       { id: 'end_height', label: 'End height (0 = level)', type: 'number', value: 0, min: 0, step: 1, unit: 'inches' },
                       { id: 'stud_spacing', label: 'Stud / reinforcing spacing', type: 'number', value: id.to_s.include?('stud') ? 16 : 0, min: 0, step: 1, unit: 'inches o.c.' }]
                    else
                      [{ id: 'width', label: 'Width', type: 'number', value: width, min: 0.01, step: 1, unit: 'inches' },
                       { id: 'depth', label: 'Depth', type: 'number', value: kind == :opening ? 8 : width, min: 0.01, step: 0.125, unit: 'inches' },
                       { id: 'height', label: 'Height', type: 'number', value: height, min: 0.01, step: 1, unit: 'inches' },
                       { id: 'sill_height', label: 'Sill / mounting height', type: 'number', value: 0, min: 0, step: 1, unit: 'inches' }]
                    end
          options += [{ id: 'material', label: 'Primary material', type: 'choice', value: id.to_s.include?('cmu') ? 'Concrete masonry' : (id.to_s.include?('stud') ? 'Steel stud' : 'Standard') },
                      { id: 'framing', label: 'Framing system', type: 'choice', value: id.to_s.include?('stud') ? 'Cold-formed steel' : 'None' },
                      { id: 'insulation', label: 'Insulation', type: 'choice', value: 'None' },
                      { id: 'sheathing', label: 'Sheathing', type: 'choice', value: 'None' },
                      { id: 'finish', label: 'Finish', type: 'choice', value: 'None' },
                      { id: 'fire_rating', label: 'Fire rating', type: 'text', value: '' },
                      { id: 'stc', label: 'STC', type: 'number', value: 0, min: 0, step: 1 },
                      { id: 'r_value', label: 'R-value', type: 'number', value: 0, min: 0, step: 1 },
                      { id: 'smoke_rating', label: 'Smoke rating', type: 'text', value: '' },
                      { id: 'security_class', label: 'Security classification', type: 'text', value: '' },
                      { id: 'ul_design', label: 'UL design', type: 'text', value: '' },
                      { id: 'ga_design', label: 'GA design', type: 'text', value: '' }]
          Tool.new(id: id, name: label, description: description, options: options)
        end.freeze
        def id = :wall
        def name = 'Wall Builder'
        def divisions = %w[03 04 05 06 07 08 09 10].freeze
        def tools = TOOLS
        def activate_tool(id, options = {})
          selected = tool(id)
          kind = Catalog.definition(selected.id).first
          normalized = options.each_with_object({}) do |(key, value), result|
            result[key.to_sym] = STRING_OPTIONS.include?(key) ? value.to_s : Float(value)
          end
          Sketchup.active_model.select_tool(Tools::WallPlacementTool.new(service: container.resolve(:wall_objects),
            object_type: selected.id.to_s, kind: kind, options: normalized))
        end
      end
    end
  end
end
