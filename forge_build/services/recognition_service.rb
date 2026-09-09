# frozen_string_literal: true

require 'time'

module ForgeBuild
  module Services
    # Converts OCR text or drawing annotations into reviewable, never automatic, model suggestions.
    class RecognitionService
      WALL_TYPES = {
        /\bCMU\b|MASONRY/i => 'reinforced_cmu_wall', /METAL\s*STUD|MTL\s*STUD/i => 'metal_stud_wall',
        /CONCRETE\s*WALL|CIP\s*WALL/i => 'concrete_wall', /CURTAIN\s*WALL/i => 'curtain_wall',
        /STOREFRONT/i => 'storefront'
      }.freeze
      ROOF_TYPES = { /TPO/i => 'tpo_membrane', /EPDM/i => 'epdm_membrane', /METAL\s*ROOF/i => 'standing_seam' }.freeze

      def recognize(text:, source: nil)
        normalized = text.to_s.gsub("\r", '')
        {
          source: source,
          dimensions: normalized.scan(/\b(\d+(?:\.\d+)?)\s*(?:'|FT)\s*(?:[- ]\s*(\d+(?:\.\d+)?)\s*(?:\"|IN))?/i).map { |feet, inches| (feet.to_f * 12) + inches.to_f },
          elevations: captures(normalized, /(?:ELEV(?:ATION)?|EL\.?)[\s:=]+([+-]?\d+(?:\.\d+)?)/i),
          rooms: captures(normalized, /(?:ROOM|RM\.?)\s*(?:NAME)?[\s:#-]+([A-Z][A-Z0-9 &-]{2,})/i),
          wall_types: captures(normalized, /(?:WALL\s*TYPE|WT)[\s:#-]+([A-Z0-9.-]+)/i),
          details: normalized.scan(/\b(\d{1,2})\s*\/\s*([ASMEP]\d{1,3}(?:\.\d+)?)\b/i).map { |detail, sheet| { detail: detail, sheet: sheet } },
          assembly_tags: normalized.scan(/\b(?:WALL|ROOF|FLOOR)[-_ ]?[A-Z]?\d{1,3}\b/i).uniq,
          grid_lines: normalized.scan(/\b(?:GRID\s*)?([A-Z]|\d{1,2})\s*(?:GRID)?\b/i).flatten.uniq,
          suggestions: suggestions(normalized),
          confirmation_required: true
        }
      end

      def suggest_feature(kind:, points:, annotation: '')
        raise ArgumentError, 'Recognition requires at least one traced point' if Array(points).empty?
        { id: "suggestion-#{kind}-#{Array(points).length}", kind: kind.to_s, points: points,
          annotation: annotation.to_s, assembly: suggestion_for(kind, annotation), confidence: confidence(annotation),
          status: 'pending', confirmation_required: true }
      end

      def confirm(suggestion, accepted:)
        suggestion.merge(status: accepted ? 'accepted' : 'rejected', confirmed_at: Time.now.utc.iso8601)
      end

      private

      def captures(text, pattern) = text.scan(pattern).flatten.map(&:strip).uniq
      def suggestions(text)
        (WALL_TYPES.merge(ROOF_TYPES)).filter_map do |pattern, assembly|
          { assembly: assembly, evidence: text[pattern], confidence: 0.85, status: 'pending', confirmation_required: true } if text.match?(pattern)
        end
      end
      def suggestion_for(kind, annotation)
        table = kind.to_s == 'roof' ? ROOF_TYPES : WALL_TYPES
        match = table.find { |pattern, _| annotation.to_s.match?(pattern) }
        match ? match.last : { 'floor' => 'slab_on_grade', 'wall' => 'metal_stud_wall', 'roof' => 'low_slope_roof', 'opening' => 'door_opening' }.fetch(kind.to_s, 'coordination_zone')
      end
      def confidence(annotation) = annotation.to_s.empty? ? 0.5 : 0.8
    end
  end
end
