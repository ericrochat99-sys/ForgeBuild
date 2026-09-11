# frozen_string_literal: true

require 'securerandom'

module ForgeBuild
  module Services
    class AssemblyService
      EDITABLE_FIELDS = %w[assembly material finish tag comments fire_rating manufacturer model_number].freeze
      POSITIVE_PARAMETERS = %w[width length height thickness depth edge_width edge_depth depression_depth span overhang
                               bearing_length seam_spacing spacing stud_spacing sill_height end_height].freeze
      NUMERIC_PARAMETERS = %w[elevation pitch slope r_value stc].freeze
      TEXT_PARAMETERS = %w[ul_design ga_design fire_rating smoke_rating security_class notes system material finish
                           framing insulation sheathing].freeze
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

      def resize(entity, parameter:, value:, shift_vector: nil, model: Sketchup.active_model)
        raise ArgumentError, 'Select a ForgeBuild assembly first' unless entity

        name = parameter.to_s
        raise ArgumentError, "Unsupported assembly dimension: #{name}" unless POSITIVE_PARAMETERS.include?(name)
        number = Float(value)
        raise ArgumentError, "#{name} must be greater than zero" unless number.positive?

        attributes = Models::ParametricObject.read(entity)
        parameters = attributes.fetch(:parameters, {}).dup
        key = parameters.key?(name.to_sym) ? name.to_sym : name
        raise ArgumentError, "#{name} is not available for this assembly" unless parameters.key?(key)

        model.start_operation('Push/Pull ForgeBuild Assembly', true)
        parameters[key] = number
        Models::ParametricObject.update(entity, parameters: parameters)
        @regeneration.regenerate(entity, model: model)
        entity.transform!(::Geom::Transformation.translation(shift_vector)) if shift_vector
        @materials.apply(entity, Models::ParametricObject.read(entity), model: model)
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
          name = key.to_s
          if TEXT_PARAMETERS.include?(name)
            result[name] = value.to_s
            next
          end
          number = Float(value)
          if POSITIVE_PARAMETERS.include?(name) && !number.positive?
            raise ArgumentError, "#{name} must be greater than zero"
          end
          result[name] = number
        end
      end
    end
  end
end
