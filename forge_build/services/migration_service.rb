# frozen_string_literal: true

module ForgeBuild
  module Services
    class MigrationService
      LEGACY_BUILDERS = { 'concrete' => 'floor', 'masonry' => 'wall' }.freeze
      def migrate(entity)
        return nil unless Models::ParametricObject.forge_build?(entity)
        attributes = Models::ParametricObject.read(entity)
        return attributes if attributes.fetch(:schema_version, 1).to_i >= Models::ParametricObject::SCHEMA_VERSION
        changes = { schema_version: Models::ParametricObject::SCHEMA_VERSION,
                    builder: LEGACY_BUILDERS.fetch(attributes[:builder].to_s, attributes[:builder].to_s),
                    parameters: attributes[:parameters] || attributes[:dimensions] || {},
                    display_mode: attributes[:display_mode] || 'detailed' }
        Models::ParametricObject.update(entity, changes)
        attributes.merge(changes)
      end

      def migrate_model(model = Sketchup.active_model)
        migrated = 0
        walk(model.entities) { |entity| migrated += 1 if migrate(entity) }
        migrated
      end

      private
      def walk(entities, &block)
        entities.each do |entity|
          yield entity
          walk(entity.entities, &block) if entity.respond_to?(:entities)
        end
      end
    end
  end
end
