# frozen_string_literal: true

require 'securerandom'

module ForgeBuild
  module Services
    class AssemblyService
      EDITABLE_FIELDS = %w[assembly material finish tag comments fire_rating manufacturer model_number].freeze
      POSITIVE_PARAMETERS = %w[width length height thickness depth].freeze
      TEXT_PARAMETERS = %w[ul_design ga_design smoke_rating security_class notes system].freeze
      def initialize(regeneration:, display:, materials:, migration:)
        @regeneration, @display, @materials, @migration = regeneration, display, materials, migration
      end

      def selected(model = Sketchup.active_model) = Models::ParametricObject.selected(model)

      def inspect(entity = selected)
        return nil unless entity && Models::ParametricObject.forge_build?(entity)
        @migration.migrate(entity)
        Models::ParametricObject.read(entity).merge(entity_name: entity.respond_to?(:name) ? entity.name : '')
      end

      def edit(entity, changes, model: Sketchup.active_model)
        raise ArgumentError, 'Select a ForgeBuild assembly first' unless entity
        normalized = changes.each_with_object({}) do |(key, value), result|
          name = key.to_s
          result[name.to_sym] = value if EDITABLE_FIELDS.include?(name)
        end
        parameters = parameter_values(changes['parameters'] || changes[:parameters] || {})
        normalized[:parameters] = Models::ParametricObject.read(entity).fetch(:parameters, {}).merge(parameters) unless parameters.empty?
        model.start_operation('Edit ForgeBuild Assembly', true)
        Models::ParametricObject.update(entity, normalized)
        @materials.apply(entity, Models::ParametricObject.read(entity), model: model)
        @regeneration.regenerate(entity, model: model) unless parameters.empty?
        @display.apply(entity, Models::ParametricObject.read(entity).fetch(:display_mode, 'detailed'))
        model.commit_operation
        inspect(entity)
      rescue StandardError
        model.abort_operation
        raise
      end

      def regenerate(entity, model: Sketchup.active_model)
        result = @regeneration.regenerate(entity, model: model)
        @display.apply(entity, Models::ParametricObject.read(entity).fetch(:display_mode, 'detailed'))
        result
      end
      def set_display(entity, mode) = @display.apply(entity, mode)
      def copy(entity, model: Sketchup.active_model)
        raise ArgumentError, 'Select a ForgeBuild assembly first' unless entity
        model.start_operation('Copy ForgeBuild Assembly', true)
        duplicate = entity.copy
        duplicate.transform!(Geom::Transformation.translation([12.inch, 12.inch, 0]))
        attributes = Models::ParametricObject.read(duplicate)
        Models::ParametricObject.update(duplicate, id: SecureRandom.uuid, parent_id: attributes[:id])
        model.commit_operation
        duplicate
      rescue StandardError
        model.abort_operation
        raise
      end

      def delete(entity, model: Sketchup.active_model)
        raise ArgumentError, 'Select a ForgeBuild assembly first' unless entity
        model.start_operation('Delete ForgeBuild Assembly', true)
        entity.erase!
        model.commit_operation
      rescue StandardError
        model.abort_operation
        raise
      end

      private
      def parameter_values(parameters)
        parameters.each_with_object({}) do |(key, value), result|
          if TEXT_PARAMETERS.include?(key.to_s)
            result[key.to_s] = value.to_s
            next
          end
          number = Float(value)
          if POSITIVE_PARAMETERS.include?(key.to_s) && !number.positive?
            raise ArgumentError, "#{key} must be greater than zero"
          end
          result[key.to_s] = number
        end
      end
    end
  end
end
