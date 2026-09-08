# frozen_string_literal: true

module ForgeBuild
  module Models
    # Stable metadata schema written to every ForgeBuild component or group.
    class ParametricObject
      DICTIONARY = 'ForgeBuild.Object'
      SCHEMA_VERSION = 2
      FIELDS = %i[id schema_version parent_id child_ids object_type builder dimensions parameters
                  assembly material fire_rating csi_division cost_code manufacturer model_number
                  finish tag comments quantities display_mode].freeze

      def self.write(entity, attributes)
        attributes.each do |key, value|
          key = key.to_sym
          raise ArgumentError, "Unsupported metadata field: #{key}" unless FIELDS.include?(key)

          entity.set_attribute(DICTIONARY, key.to_s, serialize(value))
        end
        entity
      end

      def self.read(entity)
        FIELDS.each_with_object({}) do |key, result|
          value = entity.get_attribute(DICTIONARY, key.to_s)
          result[key] = deserialize(value) unless value.nil?
        end
      end

      def self.forge_build?(entity)
        !entity.get_attribute(DICTIONARY, 'builder').nil?
      end

      def self.selected(model = Sketchup.active_model)
        model.selection.find { |entity| forge_build?(entity) }
      end

      def self.update(entity, changes)
        write(entity, read(entity).merge(changes))
      end

      def self.serialize(value)
        value.is_a?(Hash) || value.is_a?(Array) ? JSON.generate(value) : value
      end
      private_class_method :serialize

      def self.deserialize(value)
        return value unless value.is_a?(String) && ['{', '['].include?(value[0])

        JSON.parse(value)
      rescue JSON::ParserError
        value
      end
      private_class_method :deserialize
    end
  end
end
