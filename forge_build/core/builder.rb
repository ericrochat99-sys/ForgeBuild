# frozen_string_literal: true

module ForgeBuild
  module Core
    # Contract shared by every first- and third-party trade builder.
    class Builder
      Tool = Struct.new(:id, :name, :description, keyword_init: true) do
        def to_h
          { id: id, name: name, description: description }
        end
      end

      attr_reader :container

      def initialize(container:)
        @container = container
      end

      def id = raise(NotImplementedError)
      def name = raise(NotImplementedError)
      def division = raise(NotImplementedError)
      def tools = [].freeze

      def tool(id)
        tools.find { |candidate| candidate.id.to_sym == id.to_sym } ||
          raise(KeyError, "Unknown #{name} tool: #{id}")
      end

      def activate_tool(_id, _options = {})
        raise NotImplementedError
      end

      def workspace_payload
        { id: id, name: name, division: division, tools: tools.map(&:to_h) }
      end
    end
  end
end
