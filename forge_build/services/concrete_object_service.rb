# frozen_string_literal: true

require 'securerandom'

module ForgeBuild
  module Services
    class ConcreteObjectService
      TYPES = %w[slab_on_grade equipment_pad].freeze

      def create(model:, origin:, width:, length:, thickness:, object_type:)
        type = object_type.to_s
        raise ArgumentError, 'Unsupported concrete object type' unless TYPES.include?(type)

        model.start_operation("Create #{display_name(type)}", true)
        group = model.active_entities.add_group
        Geometry::RectangularPrism.create(entities: group.entities, origin: origin, width: width,
                                          length: length, height: thickness)
        group.name = "ForgeBuild #{display_name(type)}"
        Models::ParametricObject.write(group, attributes(type, width, length, thickness))
        model.commit_operation
        group
      rescue StandardError
        model.abort_operation
        raise
      end

      def attributes(type, width, length, thickness)
        {
          id: SecureRandom.uuid, object_type: type, builder: 'concrete',
          dimensions: { width: width.to_f, length: length.to_f, thickness: thickness.to_f },
          assembly: display_name(type), material: 'Cast-in-place concrete', csi_division: '03',
          cost_code: type == 'slab_on_grade' ? '03 30 00' : '03 30 00',
          quantities: { area_sq_in: width.to_f * length.to_f,
                        volume_cu_in: width.to_f * length.to_f * thickness.to_f }
        }
      end

      private

      def display_name(type)
        type.split('_').map(&:capitalize).join(' ')
      end
    end
  end
end
