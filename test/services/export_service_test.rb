# frozen_string_literal: true

require 'tmpdir'
require_relative '../test_helper'
require_relative '../../forge_build/services/export_service'

module ForgeBuild
  module Services
    class ExportServiceTest < Minitest::Test
      FakeModel = Struct.new(:title)
      FakeInformation = Struct.new(:payload) do
        def report(**_args) = payload
      end

      def test_exports_complete_delivery_package
        payload = { generated_at: 'now', object_count: 1,
                    takeoff: [{ assembly: 'Slab', quantities: { area_sq_ft: 100 } }],
                    materials: [{ material: 'Concrete', quantities: { volume_cy: 5 } }],
                    schedules: { 'All Objects' => [{ id: '1', dimensions: {}, quantities: { count: 1 } }] },
                    validations: [], missing_information: [], clashes: [], classifications: [], alternates: [], allowances: [] }
        service = ExportService.new(information: FakeInformation.new(payload))
        Dir.mktmpdir do |directory|
          root = service.export(model: FakeModel.new('Test School'), directory: directory)
          assert File.file?(File.join(root, 'quantity_takeoff.csv'))
          assert File.file?(File.join(root, 'ForgeBuild_Workbook.xml'))
          assert File.file?(File.join(root, 'assembly_summary.json'))
          assert_includes File.read(File.join(root, 'quantity_takeoff.csv')), 'area_sq_ft'
        end
      end
    end
  end
end
