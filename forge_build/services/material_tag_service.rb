# frozen_string_literal: true

module ForgeBuild
  module Services
    class MaterialTagService
      TAG_PREFIX = 'ForgeBuild'.freeze
      COLORS = { 'floor' => [150, 150, 150], 'wall' => [184, 116, 74], 'roof' => [83, 99, 115] }.freeze
      def apply(entity, attributes, model: Sketchup.active_model)
        builder = attributes[:builder].to_s
        material_name = attributes[:material].to_s.empty? ? "ForgeBuild #{builder.capitalize}" : attributes[:material].to_s
        material = model.materials[material_name] || model.materials.add(material_name)
        material.color = COLORS.fetch(builder, [180, 180, 180]) if material.respond_to?(:color=)
        entity.material = material if entity.respond_to?(:material=)
        tag_name = attributes[:tag].to_s.empty? ? "#{TAG_PREFIX} - #{builder.capitalize}" : attributes[:tag].to_s
        tag = model.layers[tag_name] || model.layers.add(tag_name)
        entity.layer = tag if entity.respond_to?(:layer=)
        Models::ParametricObject.update(entity, material: material_name, tag: tag_name)
      end
    end
  end
end
