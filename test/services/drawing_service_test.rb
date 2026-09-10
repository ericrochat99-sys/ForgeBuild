# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../forge_build/services/drawing_service'

module ForgeBuild
  module Services
    class DrawingServiceTest < Minitest::Test
      class FakeModel
        attr_reader :events, :active_view
        def initialize
          @attributes = {}
          @events = []
          @entities = []
          @selection = FakeSelection.new
          @active_view = FakeView.new
        end
        def get_attribute(dictionary, key, default = nil) = @attributes.fetch([dictionary, key], default)
        def set_attribute(dictionary, key, value) = @attributes[[dictionary, key]] = value
        def entities = @entities
        def selection = @selection
        def find_entity_by_persistent_id(id) = @entities.find { |entity| entity.persistent_id == id }
        def import(_path, _options)
          raise 'Undo operation already open' if @operation_open
          @events << :import
          @entities << FakeEntity.new(11)
          true
        end
        def start_operation(*_args)
          @operation_open = true
          @events << :start_operation
        end
        def commit_operation
          @operation_open = false
          @events << :commit_operation
        end
        def abort_operation
          @operation_open = false
          @events << :abort_operation
        end
      end
      class FakeSelection < Array
        def add(entity) = self << entity
      end
      class FakeView
        attr_reader :zoomed
        def zoom(entity) = @zoomed = entity
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

      def test_import_finishes_before_metadata_undo_operation_starts
        result = @service.import(model: @model, path: '/plans/A101.pdf', sheet: 'A101')
        assert_equal [:import, :start_operation, :commit_operation], @model.events
        assert_equal 'A101.pdf', result[:filename]
      end

      def test_focus_selects_and_fits_imported_plan_in_modeling_area
        drawing = @service.import(model: @model, path: '/plans/A101.pdf', sheet: 'A101')
        result = @service.focus(model: @model, drawing: drawing)
        assert_equal [result[:entity]], @model.selection
        assert_same result[:entity], @model.active_view.zoomed
      end
    end
  end
end
