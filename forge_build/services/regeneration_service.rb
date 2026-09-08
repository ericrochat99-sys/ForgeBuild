# frozen_string_literal: true

module ForgeBuild
  module Services
    # Routes a stored assembly back to its builder-specific geometry handler.
    # Handlers are deliberately registered by [builder, object_type] so the core
    # does not need to know how floors, walls, or roofs construct their geometry.
    class RegenerationService
      def initialize
        @handlers = {}
      end

      def register(builder:, object_type:, &handler)
        raise ArgumentError, 'A regeneration handler is required' unless handler

        @handlers[[builder.to_s, object_type.to_s]] = handler
        self
      end

      def registered?(builder:, object_type:)
        @handlers.key?([builder.to_s, object_type.to_s])
      end

      def regenerate(entity, model: Sketchup.active_model)
        attributes = Models::ParametricObject.read(entity)
        key = [attributes.fetch(:builder).to_s, attributes.fetch(:object_type).to_s]
        handler = @handlers.fetch(key) { raise KeyError, "No regeneration handler for #{key.join('/')}" }
        handler.call(entity: entity, model: model, attributes: attributes)
      end
    end
  end
end
