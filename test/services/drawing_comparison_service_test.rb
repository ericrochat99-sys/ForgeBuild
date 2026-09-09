# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../forge_build/services/drawing_comparison_service'

module ForgeBuild
  module Services
    class DrawingComparisonServiceTest < Minitest::Test
      def test_reports_matched_drawing_only_and_model_only_conditions
        objects = [{ id: '1', object_type: 'metal_stud_wall', assembly: 'Wall', comments: '', tag: '' },
                   { id: '2', object_type: 'slab_on_grade', assembly: 'Slab', comments: '', tag: '' }]
        features = [{ assembly: 'metal_stud_wall', kind: 'wall' }, { assembly: 'door_opening', kind: 'opening', annotation: 'D1' }]
        result = DrawingComparisonService.new.compare(model_objects: objects, recognized_features: features)
        assert_equal 1, result[:matched_count]
        assert_equal 1, result[:unresolved_count]
        assert_equal 1, result[:model_only].length
      end
    end
  end
end
