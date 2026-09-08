# frozen_string_literal: true

module ForgeBuild
  module Core
    # Registry through which first-party and future third-party modules advertise capabilities.
    class ModuleRegistry
      Entry = Struct.new(:id, :name, :version, :category, :divisions, :description, :factory, keyword_init: true) do
        def to_h
          { id: id, name: name, version: version, category: category, divisions: divisions,
            description: description }
        end
      end

      def initialize
        @entries = {}
      end

      # Registers a module without modifying application boot code.
      def register(id:, name:, version:, category: 'Building Assembly', divisions: [], description: '', &factory)
        key = id.to_sym
        raise ArgumentError, "Module already registered: #{key}" if @entries.key?(key)
        raise ArgumentError, 'A module factory is required' unless factory

        @entries[key] = Entry.new(id: key, name: name, version: version, category: category,
                                  divisions: Array(divisions).map(&:to_s).freeze,
                                  description: description.to_s, factory: factory)
      end

      # Returns registered module descriptors.
      def entries
        @entries.values.dup.freeze
      end

      # Builds a registered module using its factory.
      def build(id)
        @entries.fetch(id.to_sym).factory.call
      end

      def fetch(id)
        @entries.fetch(id.to_sym)
      end
    end
  end
end
