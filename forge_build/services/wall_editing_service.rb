# frozen_string_literal: true

require 'securerandom'

module ForgeBuild
  module Services
    class WallEditingService
      def initialize(regeneration:) = @regeneration = regeneration
      def walls(model = Sketchup.active_model)
        model.selection.select { |entity| Models::ParametricObject.forge_build?(entity) && Models::ParametricObject.read(entity)[:builder] == 'wall' }
      end

      def stretch(entity, length, model: Sketchup.active_model)
        update_length(entity, Float(length), model)
      end

      def split(entity, distance, model: Sketchup.active_model)
        attrs = Models::ParametricObject.read(entity)
        original = number(attrs[:parameters], 'length')
        cut = Float(distance)
        raise ArgumentError, 'Split must fall within the wall length' unless cut.positive? && cut < original
        model.start_operation('Split ForgeBuild Wall', true)
        duplicate = entity.copy
        Models::ParametricObject.update(duplicate, id: SecureRandom.uuid, parent_id: attrs[:id])
        set_length(entity, cut, model)
        set_length(duplicate, original - cut, model)
        duplicate.transformation = entity.transformation * ::Geom::Transformation.translation([cut, 0, 0])
        model.commit_operation
        duplicate
      rescue StandardError
        model.abort_operation
        raise
      end

      def join(entities, model: Sketchup.active_model)
        raise ArgumentError, 'Select exactly two ForgeBuild walls' unless entities.length == 2
        model.start_operation('Join ForgeBuild Walls', true)
        total = entities.sum { |entity| number(Models::ParametricObject.read(entity)[:parameters], 'length') }
        set_length(entities.first, total, model)
        entities.last.erase!
        model.commit_operation
        entities.first
      rescue StandardError
        model.abort_operation
        raise
      end

      def offset(entity, distance, model: Sketchup.active_model)
        model.start_operation('Offset ForgeBuild Wall', true)
        duplicate = entity.copy
        attrs = Models::ParametricObject.read(duplicate)
        Models::ParametricObject.update(duplicate, id: SecureRandom.uuid, parent_id: attrs[:id])
        duplicate.transformation = entity.transformation * ::Geom::Transformation.translation([0, Float(distance), 0])
        model.commit_operation
        duplicate
      rescue StandardError
        model.abort_operation
        raise
      end

      def connect(entities)
        raise ArgumentError, 'Select two or more ForgeBuild walls' if entities.length < 2
        root = Models::ParametricObject.read(entities.first)
        child_ids = entities.drop(1).map do |entity|
          attrs = Models::ParametricObject.read(entity)
          Models::ParametricObject.update(entity, parent_id: root[:id])
          attrs[:id]
        end
        Models::ParametricObject.update(entities.first, child_ids: (Array(root[:child_ids]) + child_ids).uniq)
      end

      def align(entities)
        raise ArgumentError, 'Select two or more ForgeBuild walls' if entities.length < 2
        target_z = entities.first.transformation.origin.z
        entities.drop(1).each do |entity|
          delta = target_z - entity.transformation.origin.z
          entity.transform!(::Geom::Transformation.translation([0, 0, delta]))
        end
        entities
      end

      def renumber(model = Sketchup.active_model)
        index = 0
        walk(model.entities).each do |entity|
          next unless Models::ParametricObject.forge_build?(entity)
          attrs = Models::ParametricObject.read(entity)
          next unless attrs[:builder] == 'wall'
          index += 1
          Models::ParametricObject.update(entity, model_number: format('W-%03d', index))
        end
        index
      end

      def schedule(model = Sketchup.active_model)
        walk(model.entities).filter_map do |entity|
          next unless Models::ParametricObject.forge_build?(entity)
          attrs = Models::ParametricObject.read(entity)
          next unless attrs[:builder] == 'wall'
          { mark: attrs[:model_number], assembly: attrs[:assembly], fire_rating: attrs[:fire_rating],
            length: attrs.dig(:dimensions, 'length'), height: attrs.dig(:dimensions, 'height'),
            area: attrs.dig(:quantities, 'area_sq_in') }
        end
      end

      private
      def update_length(entity, length, model)
        raise ArgumentError, 'Length must be greater than zero' unless length.positive?
        model.start_operation('Stretch ForgeBuild Wall', true)
        set_length(entity, length, model)
        model.commit_operation
        entity
      rescue StandardError
        model.abort_operation
        raise
      end
      def set_length(entity, length, model)
        attrs = Models::ParametricObject.read(entity)
        parameters = attrs.fetch(:parameters).merge('length' => length)
        Models::ParametricObject.update(entity, parameters: parameters)
        @regeneration.regenerate(entity, model: model)
      end
      def number(hash, key) = Float(hash[key] || hash[key.to_sym])
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
