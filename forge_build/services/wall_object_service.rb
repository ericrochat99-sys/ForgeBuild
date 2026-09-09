# frozen_string_literal: true

require 'securerandom'
require_relative '../builders/wall/catalog'

module ForgeBuild
  module Services
    class WallObjectService
      CHILD_KINDS = %i[layer opening point].freeze
      def initialize(materials: nil) = @materials = materials

      def create(model:, object_type:, origin:, endpoint: nil, thickness: nil, height: nil,
                 width: nil, depth: nil, sill_height: 0, end_height: 0, stud_spacing: 0,
                 fire_rating: '', stc: 0, ul_design: '', ga_design: '', notes: '', **extra)
        type = object_type.to_sym
        kind, label, _description, default_width, default_height, _cost_code = Builders::Wall::Catalog.definition(type)
        parent = eligible_parent(model, kind)
        parameters = if %i[line layer].include?(kind)
                       vector = endpoint - origin
                       raise ArgumentError, 'Wall run must have a measurable length' unless vector.length.positive?
                       { length: vector.length.to_f, thickness: Float(thickness || default_width),
                         height: Float(height || default_height), end_height: Float(end_height),
                         stud_spacing: Float(stud_spacing), system: type.to_s }
                     else
                       { width: Float(width || default_width), depth: Float(depth || thickness || 4),
                         height: Float(height || default_height), sill_height: Float(sill_height), system: type.to_s }
                     end
        parameters.merge!(extra.transform_keys(&:to_sym))
        parameters[:notes] = notes.to_s
        model.start_operation("Create #{label}", true)
        group = model.active_entities.add_group
        build(group.entities, kind, parameters)
        position(group, kind, origin, endpoint, parameters)
        group.name = "ForgeBuild #{label}"
        Models::ParametricObject.write(group, attributes(type, kind, label, parameters, parent,
                                                          fire_rating, stc, ul_design, ga_design))
        link_parent(parent, group) if parent
        @materials&.apply(group, Models::ParametricObject.read(group), model: model)
        model.commit_operation
        group
      rescue StandardError
        model.abort_operation
        raise
      end

      def regenerate(entity:, model:, attributes:)
        type = attributes.fetch(:object_type).to_sym
        kind, label, _description, default_width, default_height, _cost_code = Builders::Wall::Catalog.definition(type)
        p = symbolize(attributes.fetch(:parameters, attributes.fetch(:dimensions)))
        p[:system] ||= type.to_s
        p[:thickness] ||= default_width if %i[line layer].include?(kind)
        p[:height] ||= default_height
        p[:end_height] ||= 0.0
        p[:stud_spacing] ||= p[:cell_spacing] || 0.0
        p[:width] ||= default_width
        p[:depth] ||= p[:thickness] || 4.0
        p[:sill_height] ||= 0.0
        kind = :line if %i[control_joint pilaster].include?(type) && p[:length]
        entity.entities.clear!
        build(entity.entities, kind, p)
        Models::ParametricObject.update(entity, parameters: p, dimensions: dimensions(kind, p),
                                        assembly: label, quantities: quantities(kind, p))
        entity
      end

      private

      def build(entities, kind, p)
        if %i[line layer].include?(kind)
          Geometry::WallAssembly.line(entities: entities, **p)
        else
          Geometry::WallAssembly.point(entities: entities, **p)
        end
      end

      def position(group, kind, origin, endpoint, p)
        if %i[line layer].include?(kind)
          vector = endpoint - origin
          x_axis = ::Geom::Vector3d.new(vector.x, vector.y, 0).normalize
          y_axis = ::Geom::Vector3d.new(-x_axis.y, x_axis.x, 0)
          group.transform!(::Geom::Transformation.axes(origin, x_axis, y_axis, Z_AXIS))
        else
          point = origin.offset(Z_AXIS, p[:sill_height])
          group.transform!(::Geom::Transformation.translation(point.to_a))
        end
      end

      def attributes(type, kind, label, p, parent, fire_rating, stc, ul_design, ga_design)
        division = Builders::Wall::Catalog.definition(type).fetch(5).split.first
        { id: SecureRandom.uuid, schema_version: Models::ParametricObject::SCHEMA_VERSION,
          parent_id: parent && Models::ParametricObject.read(parent)[:id], child_ids: [],
          object_type: type.to_s, builder: 'wall', dimensions: dimensions(kind, p), parameters: p,
          assembly: label, material: material(type, division), fire_rating: fire_rating.to_s,
          csi_division: division, cost_code: Builders::Wall::Catalog.definition(type).fetch(5),
          manufacturer: '', model_number: '', finish: '', tag: "ForgeBuild - Wall - #{label}",
          comments: p[:notes], quantities: quantities(kind, p), display_mode: 'detailed' }.tap do |data|
            data[:parameters].merge!(stc: stc.to_f, ul_design: ul_design.to_s, ga_design: ga_design.to_s)
          end
      end

      def dimensions(kind, p)
        return { length: p[:length], thickness: p[:thickness], height: p[:height], end_height: p[:end_height] } if %i[line layer].include?(kind)
        { width: p[:width], depth: p[:depth], height: p[:height], sill_height: p[:sill_height] }
      end

      def quantities(kind, p)
        if %i[line layer].include?(kind)
          average_height = (p[:height] + (p[:end_height].to_f.positive? ? p[:end_height] : p[:height])) / 2.0
          { length_in: p[:length], area_sq_in: p[:length] * average_height,
            volume_cu_in: p[:length] * average_height * p[:thickness],
            stud_count: p[:stud_spacing].to_f.positive? ? (p[:length] / p[:stud_spacing]).floor + 1 : 0 }
        else
          { count: 1, opening_area_sq_in: p[:width] * p[:height], volume_cu_in: p[:width] * p[:depth] * p[:height] }
        end
      end

      def eligible_parent(model, kind)
        return nil unless CHILD_KINDS.include?(kind)
        entity = Models::ParametricObject.selected(model)
        attrs = entity && Models::ParametricObject.read(entity)
        entity if attrs && attrs[:builder] == 'wall'
      end
      def link_parent(parent, child)
        attrs = Models::ParametricObject.read(parent)
        Models::ParametricObject.update(parent, child_ids: (Array(attrs[:child_ids]) + [Models::ParametricObject.read(child)[:id]]).uniq)
      end
      def material(type, division)
        return 'Concrete masonry units' if type.to_s.include?('cmu')
        return 'Cast-in-place concrete' if type.to_s.include?('concrete') || type == :tilt_up_panel
        return 'Gypsum board' if type.to_s.include?('board')
        return 'Steel framing' if %w[05 09].include?(division)
        Builders::Wall::Catalog.definition(type).fetch(1)
      end
      def symbolize(hash) = hash.each_with_object({}) { |(key, value), result| result[key.to_sym] = value }
    end
  end
end
