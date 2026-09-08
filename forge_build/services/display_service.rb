# frozen_string_literal: true

module ForgeBuild
  module Services
    class DisplayService
      MODES = %w[2d simplified detailed].freeze
      def apply(entity, mode)
        selected = mode.to_s
        raise ArgumentError, 'Unknown display mode' unless MODES.include?(selected)
        entity.entities.each do |item|
          next unless defined?(Sketchup::Edge) && (item.is_a?(Sketchup::Edge) || item.is_a?(Sketchup::Face))
          item.hidden = case selected
                        when '2d' then item.is_a?(Sketchup::Face)
                        when 'simplified' then item.is_a?(Sketchup::Edge)
                        else false
                        end
        end
        Models::ParametricObject.update(entity, display_mode: selected)
        entity
      end
    end
  end
end
