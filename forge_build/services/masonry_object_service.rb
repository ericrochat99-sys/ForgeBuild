# frozen_string_literal: true

require 'securerandom'

module ForgeBuild
  module Services
    class MasonryObjectService
      TYPES = %w[cmu_wall brick_wall brick_veneer stone_veneer pilaster control_joint lintel
                 bond_beam grouted_cells reinforcing].freeze
      MATERIALS = {
        'cmu_wall' => 'Concrete masonry units', 'brick_wall' => 'Clay masonry units',
        'brick_veneer' => 'Brick veneer', 'stone_veneer' => 'Stone veneer',
        'pilaster' => 'Reinforced concrete masonry', 'control_joint' => 'Masonry joint system',
        'lintel' => 'Masonry lintel', 'bond_beam' => 'Grouted bond beam',
        'grouted_cells' => 'Masonry grout', 'reinforcing' => 'Masonry reinforcing steel'
      }.freeze
      COST_CODES = {
        'cmu_wall' => '04 22 00', 'brick_wall' => '04 21 13', 'brick_veneer' => '04 21 13',
        'stone_veneer' => '04 43 00', 'pilaster' => '04 22 00', 'control_joint' => '04 05 23',
        'lintel' => '04 05 19', 'bond_beam' => '04 22 00', 'grouted_cells' => '04 05 16',
        'reinforcing' => '04 05 19'
      }.freeze

      def create(model:, origin:, endpoint:, thickness:, height:, object_type:, cell_spacing: 48)
        type = validate_type(object_type)
        vector = endpoint - origin
        run_length = vector.length
        raise ArgumentError, 'Masonry run must have a measurable length' unless run_length.positive?

        model.start_operation("Create #{display_name(type)}", true)
        group = model.active_entities.add_group
        local_origin = ::Geom::Point3d.new(0, 0, 0)
        Geometry::RectangularPrism.create(entities: group.entities, origin: local_origin,
                                          width: run_length, length: thickness, height: height)
        x_axis = ::Geom::Vector3d.new(vector.x, vector.y, 0)
        x_axis.normalize!
        y_axis = ::Geom::Vector3d.new(-x_axis.y, x_axis.x, 0)
        group.transform!(::Geom::Transformation.axes(origin, x_axis, y_axis, Z_AXIS))
        group.name = "ForgeBuild #{display_name(type)}"
        Models::ParametricObject.write(group, attributes(type, run_length, thickness, height, cell_spacing))
        model.commit_operation
        group
      rescue StandardError
        model.abort_operation
        raise
      end

      def attributes(object_type, run_length, thickness, height, cell_spacing = 48)
        type = validate_type(object_type)
        spacing = Float(cell_spacing)
        length = run_length.to_f
        wall_area = length * height.to_f
        {
          id: SecureRandom.uuid, schema_version: Models::ParametricObject::SCHEMA_VERSION,
          parent_id: nil, child_ids: [], object_type: type, builder: 'wall',
          dimensions: { length: length, thickness: thickness.to_f, height: height.to_f,
                        cell_spacing: spacing },
          parameters: { length: length, thickness: thickness.to_f, height: height.to_f,
                        cell_spacing: spacing },
          assembly: display_name(type), material: MATERIALS.fetch(type), csi_division: '04',
          cost_code: COST_CODES.fetch(type),
          display_mode: 'detailed', quantities: {
            length_in: length, area_sq_in: wall_area,
            volume_cu_in: wall_area * thickness.to_f,
            reinforcing_locations: (length / spacing).floor + 1
          }
        }
      end

      private

      def validate_type(object_type)
        type = object_type.to_s
        raise ArgumentError, 'Unsupported masonry object type' unless TYPES.include?(type)

        type
      end

      def display_name(type)
        type.split('_').map(&:capitalize).join(' ')
      end
    end
  end
end
