# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../forge_build/services/drawing_service'

module ForgeBuild
  module Services
    class DrawingServiceTest < Minitest::Test
      class FakeModel
        def initialize = @attributes = {}
        def get_attribute(dictionary, key, default = nil) = @attributes.fetch([dictionary, key], default)
        def set_attribute(dictionary, key, value) = @attributes[[dictionary, key]] = value
      end
      FakeEntity = Struct.new(:persistent_id, :name) do
        def set_attribute(*_args); end
      end

      def setup
        @model = FakeModel.new
        @service = DrawingService.new
      end

      def test_registers_and_calibrates_drawing
        drawing = @service.register(model: @model, entity: FakeEntity.new(10), path: '/plans/A101.pdf',
                                    discipline: 'architectural', sheet: 'A101', revision: '0', page: 2)
        assert_equal 1, @service.registry(@model).length
        calibrated = @service.calibrate(model: @model, id: drawing[:id], measured_length: 6, actual_length: 12)
        assert_equal 2.0, calibrated[:scale]
      end

      def test_tracks_and_compares_revisions
        drawing = @service.register(model: @model, entity: nil, path: 'A101-r0.pdf', discipline: 'architectural')
        @service.add_revision(model: @model, id: drawing[:id], revision: '0', path: 'A101-r0.pdf')
        @service.add_revision(model: @model, id: drawing[:id], revision: '1', path: 'A101-r1.pdf', notes: 'Addendum 1')
        result = @service.compare_revisions(model: @model, id: drawing[:id], older: '0', newer: '1')
        assert result[:changed]
      end
    end
  end
end
