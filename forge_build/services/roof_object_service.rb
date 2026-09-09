# frozen_string_literal: true

require 'securerandom'
require_relative '../builders/roof/catalog'

module ForgeBuild
  module Services
    class RoofObjectService
      CHILD_KINDS = %i[layer point].freeze
      def initialize(materials: nil) = @materials = materials
      def create(model:, object_type:, origin:, endpoint: nil, width: nil, length: nil, depth: nil,
                 thickness: nil, height: nil, pitch: 0, elevation: 0, spacing: 0, seam_spacing: 0,
                 overhang: 0, notes: '', **extra)
        type = object_type.to_sym
        kind, label, _description, default_size, default_pitch_or_height, cost_code = Builders::Roof::Catalog.definition(type)
        parent = eligible_parent(model, kind)
        p = if %i[area layer].include?(kind)
              { width: Float(width), length: Float(length), thickness: Float(thickness || default_size),
                pitch: Float(pitch || default_pitch_or_height), elevation: Float(elevation),
                seam_spacing: Float(seam_spacing), overhang: Float(overhang), system: type.to_s }
            elsif kind == :line
              vector = endpoint - origin
              raise ArgumentError, 'Roof run must have a measurable length' unless vector.length.positive?
              { length: vector.length.to_f, width: Float(width || default_size),
                height: Float(height || default_pitch_or_height), spacing: Float(spacing), system: type.to_s }
            else
              { width: Float(width || default_size), depth: Float(depth || default_size),
                height: Float(height || default_pitch_or_height), elevation: Float(elevation), system: type.to_s }
            end
        p.merge!(extra.transform_keys(&:to_sym))
        p[:notes] = notes.to_s
        model.start_operation("Create #{label}", true)
        group = model.active_entities.add_group
        build(group.entities, kind, p)
        position(group, kind, origin, endpoint, p)
        group.name = "ForgeBuild #{label}"
        Models::ParametricObject.write(group, attributes(type, kind, label, cost_code, p, parent))
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
        kind, label, _description, default_size, default_pitch_or_height, _cost_code = Builders::Roof::Catalog.definition(type)
        p = symbolize(attributes.fetch(:parameters, attributes.fetch(:dimensions)))
        p[:system] ||= type.to_s
        p[:thickness] ||= default_size
        p[:pitch] ||= default_pitch_or_height if %i[area layer].include?(kind)
        p[:elevation] ||= 0.0
        p[:seam_spacing] ||= 0.0
        p[:overhang] ||= 0.0
        p[:width] ||= default_size
        p[:depth] ||= default_size
        p[:height] ||= default_pitch_or_height
        p[:spacing] ||= 0.0
        entity.entities.clear!
        build(entity.entities, kind, p)
        Models::ParametricObject.update(entity, parameters: p, dimensions: dimensions(kind, p),
                                        assembly: label, quantities: quantities(kind, p))
        entity
      end

      private
      def build(entities, kind, p)
        case kind
        when :area, :layer then Geometry::RoofAssembly.area(entities: entities, **p)
        when :line then Geometry::RoofAssembly.linear(entities: entities, **p)
        else Geometry::RoofAssembly.point(entities: entities, **p)
        end
      end
      def position(group, kind, origin, endpoint, p)
        if kind == :line
          vector = endpoint - origin
          x_axis = ::Geom::Vector3d.new(vector.x, vector.y, 0).normalize
          y_axis = ::Geom::Vector3d.new(-x_axis.y, x_axis.x, 0)
          group.transform!(::Geom::Transformation.axes(origin, x_axis, y_axis, Z_AXIS))
        else
          point = kind == :point ? origin.offset(Z_AXIS, p[:elevation]) : origin
          group.transform!(::Geom::Transformation.translation(point.to_a))
        end
      end
      def attributes(type, kind, label, cost_code, p, parent)
        { id: SecureRandom.uuid, schema_version: Models::ParametricObject::SCHEMA_VERSION,
          parent_id: parent && Models::ParametricObject.read(parent)[:id], child_ids: [],
          object_type: type.to_s, builder: 'roof', dimensions: dimensions(kind, p), parameters: p,
          assembly: label, material: material(type), csi_division: cost_code.split.first,
          cost_code: cost_code, manufacturer: '', model_number: '', finish: '',
          tag: "ForgeBuild - Roof - #{label}", comments: p[:notes], quantities: quantities(kind, p),
          display_mode: 'detailed' }
      end
      def dimensions(kind, p)
        return { length: p[:length], width: p[:width], height: p[:height] } if kind == :line
        return { width: p[:width], depth: p[:depth], height: p[:height], elevation: p[:elevation] } if kind == :point
        { width: p[:width], length: p[:length], thickness: p[:thickness], pitch: p[:pitch], elevation: p[:elevation] }
      end
      def quantities(kind, p)
        if %i[area layer].include?(kind)
          slope_factor = Math.sqrt(1.0 + (p[:pitch].to_f / 12.0)**2)
          { plan_area_sq_in: p[:width] * p[:length], roof_area_sq_in: p[:width] * p[:length] * slope_factor,
            volume_cu_in: p[:width] * p[:length] * p[:thickness] }
        elsif kind == :line
          { length_in: p[:length], volume_cu_in: p[:length] * p[:width] * p[:height],
            member_count: p[:spacing].to_f.positive? ? (p[:length] / p[:spacing]).floor + 1 : 1 }
        else
          { count: 1, area_sq_in: p[:width] * p[:depth], volume_cu_in: p[:width] * p[:depth] * p[:height] }
        end
      end
      def eligible_parent(model, kind)
        return nil unless CHILD_KINDS.include?(kind)
        entity = Models::ParametricObject.selected(model)
        attrs = entity && Models::ParametricObject.read(entity)
        entity if attrs && attrs[:builder] == 'roof'
      end
      def link_parent(parent, child)
        attrs = Models::ParametricObject.read(parent)
        Models::ParametricObject.update(parent, child_ids: (Array(attrs[:child_ids]) + [Models::ParametricObject.read(child)[:id]]).uniq)
      end
      def material(type)
        return 'Structural steel' if type.to_s.include?('steel') || %i[bridging purlin].include?(type)
        return 'Wood framing' if %i[wood_rafter timber_member roof_truss ridge_member blocking].include?(type)
        Builders::Roof::Catalog.definition(type).fetch(1)
      end
      def symbolize(hash) = hash.each_with_object({}) { |(key, value), result| result[key.to_sym] = value }
    end
  end
end
