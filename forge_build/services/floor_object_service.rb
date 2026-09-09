# frozen_string_literal: true

require 'securerandom'
require_relative '../builders/floor/catalog'

module ForgeBuild
  module Services
    class FloorObjectService
      CHILD_TYPES = %i[vapor_retarder underslab_insulation granular_base prepared_subgrade metal_deck
                       slab_recess construction_joint control_joint isolation_joint pour_strip
                       expansion_joint trench coordination_zone floor_drain sleeve rectangular_opening
                       circular_opening polygon_opening blockout opening_reinforcement reinforcing_zone].freeze
      def initialize(materials: nil) = @materials = materials
      def create_from_face(model:, face:, object_type:, thickness:)
        points = face.outer_loop.vertices.map { |vertex| vertex.position }
        raise ArgumentError, 'A floor boundary requires at least three points' if points.length < 3
        model.start_operation('Create Floor From Face', true)
        group = model.active_entities.add_group
        created = group.entities.add_face(points)
        raise 'Unable to create floor boundary' unless created
        created.reverse! if created.normal.z.negative?
        created.pushpull(Float(thickness))
        label = Builders::Floor::Catalog.definition(object_type).fetch(1)
        parameters = { vertices: points.map(&:to_a), thickness: Float(thickness), elevation: 0.0,
                       slope: 0.0, spacing: 0.0, notes: '' }
        group.name = "ForgeBuild #{label}"
        Models::ParametricObject.write(group, polygon_attributes(object_type, label, parameters, face.area.to_f))
        @materials&.apply(group, Models::ParametricObject.read(group), model: model)
        model.commit_operation
        group
      rescue StandardError
        model.abort_operation
        raise
      end

      def create(model:, object_type:, origin:, endpoint: nil, width: nil, length: nil, depth: nil,
                 thickness: nil, height: nil, elevation: 0, spacing: 0, slope: 0, notes: '', **extra)
        type = object_type.to_sym
        kind, label, _description, default_size, default_height = Builders::Floor::Catalog.definition(type)
        parameters = normalized_parameters(kind, origin, endpoint, width, length, depth,
                                           thickness || default_size, height || default_height,
                                           elevation, spacing, slope, notes, extra)
        parameters[:system] = type.to_s
        parent = eligible_parent(model, type)
        model.start_operation("Create #{label}", true)
        group = model.active_entities.add_group
        build(group.entities, kind, parameters)
        position(group, kind, origin, endpoint, parameters)
        group.name = "ForgeBuild #{label}"
        Models::ParametricObject.write(group, attributes(type, kind, label, parameters, parent))
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
        kind, label = Builders::Floor::Catalog.definition(type)
        parameters = symbolize(attributes.fetch(:parameters, attributes.fetch(:dimensions)))
        parameters[:elevation] ||= 0.0
        parameters[:slope] ||= 0.0
        parameters[:spacing] ||= 0.0
        parameters[:notes] ||= ''
        parameters[:system] ||= type.to_s
        parameters[:height] ||= parameters[:thickness]
        parameters[:thickness] ||= parameters[:height]
        parameters[:width] ||= parameters[:thickness] unless kind == :face
        parameters[:length] ||= parameters[:width] unless kind == :face
        entity.entities.clear!
        build(entity.entities, kind, parameters)
        Models::ParametricObject.update(entity, dimensions: dimensions(kind, parameters),
                                        quantities: quantities(kind, parameters), assembly: label)
        entity
      end

      private

      def normalized_parameters(kind, origin, endpoint, width, length, depth, thickness, height, elevation, spacing, slope, notes, extra)
        values = { width: Float(width || depth || thickness), length: Float(length || width || depth || thickness),
                   thickness: Float(thickness), height: Float(height), elevation: Float(elevation),
                   spacing: Float(spacing), slope: Float(slope), notes: notes.to_s }
        extra.each { |key, value| values[key.to_sym] = value.is_a?(Numeric) ? value.to_f : value }
        if kind == :linear
          vector = endpoint - origin
          raise ArgumentError, 'Run must have a measurable length' unless vector.length.positive?
          values[:length] = vector.length.to_f
          values[:width] = Float(width || thickness)
          values[:height] = Float(height)
        end
        values.each { |key, value| raise ArgumentError, "#{key} cannot be negative" if value.is_a?(Numeric) && value.negative? && key != :elevation }
        values
      end

      def build(entities, kind, p)
        z = kind == :area ? p[:elevation] : 0
        origin = ::Geom::Point3d.new(0, 0, z)
        case kind
        when :area
          Geometry::FloorAssembly.area(entities: entities, **p.merge(thickness: [p[:thickness], 0.01].max))
        when :linear
          Geometry::FloorAssembly.linear(entities: entities, **p)
        when :point
          Geometry::FloorAssembly.point(entities: entities, **p)
        end
      end

      def position(group, kind, origin, endpoint, p)
        if kind == :linear
          vector = endpoint - origin
          x_axis = ::Geom::Vector3d.new(vector.x, vector.y, 0).normalize
          y_axis = ::Geom::Vector3d.new(-x_axis.y, x_axis.x, 0)
          group.transform!(::Geom::Transformation.axes(origin, x_axis, y_axis, Z_AXIS))
        else
          group.transform!(::Geom::Transformation.translation(origin.to_a))
        end
      end

      def attributes(type, kind, label, p, parent = nil)
        { id: SecureRandom.uuid, schema_version: Models::ParametricObject::SCHEMA_VERSION,
          parent_id: parent && Models::ParametricObject.read(parent)[:id], child_ids: [], object_type: type.to_s, builder: 'floor',
          dimensions: dimensions(kind, p), parameters: p, assembly: label,
          material: material(type), csi_division: division(type), cost_code: cost_code(type),
          tag: "ForgeBuild - Floor - #{label}", comments: p[:notes], display_mode: 'detailed',
          quantities: quantities(kind, p) }
      end

      def polygon_attributes(type, label, p, area)
        { id: SecureRandom.uuid, schema_version: Models::ParametricObject::SCHEMA_VERSION,
          parent_id: nil, child_ids: [], object_type: type.to_s, builder: 'floor',
          dimensions: { area_sq_in: area, thickness: p[:thickness] }, parameters: p,
          assembly: label, material: 'Cast-in-place concrete', csi_division: '03',
          cost_code: '03 30 00', tag: "ForgeBuild - Floor - #{label}", display_mode: 'detailed',
          quantities: { area_sq_in: area, volume_cu_in: area * p[:thickness] } }
      end

      def dimensions(kind, p)
        return { length: p[:length], width: p[:width], height: p[:height] } if kind == :linear
        return { vertices: p[:vertices], thickness: p[:thickness] } if kind == :face
        { width: p[:width], length: p[:length], thickness: p[:thickness], height: p[:height], elevation: p[:elevation] }
      end
      def quantities(kind, p)
        case kind
        when :area then { area_sq_in: p[:width] * p[:length], volume_cu_in: p[:width] * p[:length] * p[:thickness] }
        when :linear then { length_in: p[:length], volume_cu_in: p[:length] * p[:width] * p[:height], member_count: p[:spacing].positive? ? (p[:length] / p[:spacing]).floor + 1 : 1 }
        when :face
          area = polygon_area(p[:vertices])
          { area_sq_in: area, volume_cu_in: area * p[:thickness] }
        else { count: 1, volume_cu_in: p[:width] * p[:length] * p[:height] }
        end
      end
      def division(type) = %i[steel_beam steel_joist bridging metal_deck pour_stop column].include?(type) ? '05' : (%i[wood_joist floor_truss].include?(type) ? '06' : '03')
      def cost_code(type) = { '03' => '03 30 00', '05' => '05 30 00', '06' => '06 10 00' }.fetch(division(type))
      def material(type) = division(type) == '05' ? 'Structural steel' : (division(type) == '06' ? 'Wood framing' : 'Cast-in-place concrete')
      def symbolize(hash) = hash.each_with_object({}) { |(key, value), result| result[key.to_sym] = value }
      def eligible_parent(model, type)
        return nil unless CHILD_TYPES.include?(type)
        entity = Models::ParametricObject.selected(model)
        attributes = entity && Models::ParametricObject.read(entity)
        entity if attributes && attributes[:builder] == 'floor'
      end
      def link_parent(parent, child)
        parent_attributes = Models::ParametricObject.read(parent)
        children = Array(parent_attributes[:child_ids])
        child_id = Models::ParametricObject.read(child)[:id]
        Models::ParametricObject.update(parent, child_ids: (children + [child_id]).uniq)
      end
      def polygon_area(vertices)
        points = vertices.map { |point| ::Geom::Point3d.new(point) }
        points.each_with_index.sum { |point, index| (point.x * points[(index + 1) % points.length].y) - (points[(index + 1) % points.length].x * point.y) }.abs / 2.0
      end
    end
  end
end
        when :face
          face = entities.add_face(p[:vertices].map { |point| ::Geom::Point3d.new(point) })
          raise 'Unable to regenerate floor boundary' unless face
          face.reverse! if face.normal.z.negative?
          face.pushpull(p[:thickness])
