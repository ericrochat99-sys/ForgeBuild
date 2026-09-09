# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../forge_build/services/recognition_service'

module ForgeBuild
  module Services
    class RecognitionServiceTest < Minitest::Test
      def test_extracts_annotations_and_requires_confirmation
        result = RecognitionService.new.recognize(text: "ROOM: CLASSROOM 101\nWALL TYPE: A1\n12'-6\"\nEL 100.5\n3/A501\n6 IN CMU")
        assert_in_delta 150, result[:dimensions].first, 0.001
        assert_includes result[:rooms], 'CLASSROOM 101'
        assert_includes result[:wall_types], 'A1'
        assert_equal 'reinforced_cmu_wall', result[:suggestions].first[:assembly]
        assert result[:confirmation_required]
      end

      def test_confirm_records_explicit_user_decision
        service = RecognitionService.new
        suggestion = service.suggest_feature(kind: :roof, points: [[0, 0], [10, 10]], annotation: 'TPO ROOF')
        assert_equal 'pending', suggestion[:status]
        assert_equal 'accepted', service.confirm(suggestion, accepted: true)[:status]
      end
    end
  end
end
