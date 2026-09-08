# frozen_string_literal: true

module ForgeBuild
  module Project
    # Domain model for project identity and high-level building attributes.
    class Project
      BUILDING_TYPES = %w[commercial education healthcare government industrial other].freeze

      attr_reader :name, :location, :building_type, :occupancy, :construction_type, :stories

      def initialize(name:, location: '', building_type: 'commercial', occupancy: '', construction_type: '', stories: 1)
        @name = required_string(name, :name)
        @location = location.to_s.strip
        @building_type = validate_building_type(building_type)
        @occupancy = occupancy.to_s.strip
        @construction_type = construction_type.to_s.strip
        @stories = validate_stories(stories)
      end

      # Returns a persistence-safe representation.
      def to_h
        { name: name, location: location, building_type: building_type, occupancy: occupancy,
          construction_type: construction_type, stories: stories }
      end

      private

      def required_string(value, field)
        result = value.to_s.strip
        raise ArgumentError, "#{field} is required" if result.empty?

        result
      end

      def validate_building_type(value)
        result = value.to_s.downcase
        raise ArgumentError, 'Unsupported building type' unless BUILDING_TYPES.include?(result)

        result
      end

      def validate_stories(value)
        result = Integer(value)
        raise ArgumentError, 'stories must be greater than zero' unless result.positive?

        result
      rescue TypeError, ArgumentError
        raise ArgumentError, 'stories must be a positive integer'
      end
    end
  end
end
