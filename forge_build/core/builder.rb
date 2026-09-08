# frozen_string_literal: true

module ForgeBuild
  module Core
    # Contract shared by every building-assembly builder.
    class Builder
      Tool = Struct.new(:id, :name, :description, :options, keyword_init: true) do
        def to_h
          { id: id, name: name, description: description, options: options || [] }
        end
      end

      attr_reader :container

      def initialize(container:)
        @container = container
      end

      def id = raise(NotImplementedError)
      def name = raise(NotImplementedError)
      def category = 'Building Assembly'
      def divisions = [].freeze
      def tools = [].freeze

      def tool(id)
        tools.find { |candidate| candidate.id.to_sym == id.to_sym } ||
          raise(KeyError, "Unknown #{name} tool: #{id}")
      end

      def activate_tool(_id, _options = {})
        raise NotImplementedError
      end

      def workspace_payload
        { id: id, name: name, category: category, divisions: divisions, tools: tools.map(&:to_h) }
      end
    end
  end
end
