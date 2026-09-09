# frozen_string_literal: true

require 'securerandom'
module ForgeBuild
  module Services
    class RoofEditingService
      def initialize(regeneration:) = @regeneration = regeneration
      def roofs(model = Sketchup.active_model)
        model.selection.select { |entity| Models::ParametricObject.forge_build?(entity) && Models::ParametricObject.read(entity)[:builder] == 'roof' }
      end
      def offset(entity, distance, model: Sketchup.active_model)
        model.start_operation('Offset ForgeBuild Roof', true)
        duplicate = entity.copy
        attrs = Models::ParametricObject.read(duplicate)
        Models::ParametricObject.update(duplicate, id: SecureRandom.uuid, parent_id: attrs[:id])
        duplicate.transform!(::Geom::Transformation.translation([0, 0, Float(distance)]))
        model.commit_operation
        duplicate
      rescue StandardError
        model.abort_operation
        raise
      end
      def connect(entities)
        raise ArgumentError, 'Select two or more ForgeBuild roof objects' if entities.length < 2
        root = Models::ParametricObject.read(entities.first)
        ids = entities.drop(1).map do |entity|
          attrs = Models::ParametricObject.read(entity)
          Models::ParametricObject.update(entity, parent_id: root[:id])
          attrs[:id]
        end
        Models::ParametricObject.update(entities.first, child_ids: (Array(root[:child_ids]) + ids).uniq)
      end
      def renumber(model = Sketchup.active_model)
        index = 0
        walk(model.entities).each do |entity|
          next unless Models::ParametricObject.forge_build?(entity)
          attrs = Models::ParametricObject.read(entity)
          next unless attrs[:builder] == 'roof'
          index += 1
          Models::ParametricObject.update(entity, model_number: format('R-%03d', index))
        end
        index
      end
      def schedule(model = Sketchup.active_model)
        walk(model.entities).filter_map do |entity|
          next unless Models::ParametricObject.forge_build?(entity)
          attrs = Models::ParametricObject.read(entity)
          next unless attrs[:builder] == 'roof'
          { mark: attrs[:model_number], assembly: attrs[:assembly], area: attrs.dig(:quantities, 'roof_area_sq_in'),
            pitch: attrs.dig(:dimensions, 'pitch'), cost_code: attrs[:cost_code] }
        end
      end
      private
      def walk(entities, result = [])
        entities.each do |entity|
          result << entity
          walk(entity.entities, result) if entity.respond_to?(:entities)
        end
        result
      end
    end
  end
end
