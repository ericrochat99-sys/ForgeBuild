# frozen_string_literal: true

module ForgeBuild
  module Core
    # Minimal lazy dependency container used to keep services replaceable in tests.
    class Container
      def initialize
        @factories = {}
        @instances = {}
      end

      # Registers a lazy service factory.
      def register(key, &factory)
        raise ArgumentError, 'A factory block is required' unless factory

        @factories[key.to_sym] = factory
      end

      # Resolves and memoizes a registered service.
      def resolve(key)
        key = key.to_sym
        @instances[key] ||= @factories.fetch(key).call
      end
    end
  end
end
