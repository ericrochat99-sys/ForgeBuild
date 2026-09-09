# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../forge_build/services/information_service'

module ForgeBuild
  module Services
    class InformationServiceTest < Minitest::Test
      def setup
        @service = InformationService.new
        @objects = [
          { id: 'w1', builder: 'wall', object_type: 'metal_stud_wall', assembly: 'Metal Stud Wall',
            material: 'Cold-formed framing', csi_division: '09', cost_code: '09 22 16', level: 'Level 1', area: 'Area A',
            building: 'School', parameters: {}, quantities: { area_sq_in: 1440, length_in: 120 }, tag: 'ForgeBuild - Wall' },
          { id: 'd1', builder: 'wall', object_type: 'door_opening', assembly: 'Door Opening',
            material: 'Opening', csi_division: '08', cost_code: '08 11 13', level: 'Level 1', area: 'Area A',
            building: 'School', parameters: {}, quantities: { count: 1 }, tag: 'ForgeBuild - Door' }
        ]
      end

      def test_takeoff_groups_and_applies_waste
        rows = @service.takeoff(@objects, default: 10)
        wall = rows.find { |row| row[:assembly] == 'Metal Stud Wall' }
        assert_in_delta 1584, wall[:quantities]['area_sq_in'], 0.001
        assert_equal 10.0, wall[:waste_factor]
      end

      def test_schedules_include_openings_and_all_objects
        schedules = @service.schedules(@objects)
        assert_equal 1, schedules['Openings'].length
        assert_equal 2, schedules['All Objects'].length
      end

      def test_validation_flags_commercial_information_gaps
        messages = @service.validations(@objects).map { |row| row[:message] }
        assert_includes messages, 'Fire rating not specified'
        assert_includes messages, 'Accessibility status not confirmed'
      end

      def test_classification_maps_to_ifc_and_dwg_fields
        rows = @service.classifications(@objects)
        assert_equal 'IfcWall', rows.first[:ifc_class]
        assert_equal 'IfcDoor', rows.last[:ifc_class]
        assert_equal 'ForgeBuild---Door', rows.last[:dwg_layer]
      end
    end
  end
end
