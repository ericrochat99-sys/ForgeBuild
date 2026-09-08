# frozen_string_literal: true
require_relative '../test_helper'
require 'services/masonry_object_service'

class MasonryObjectServiceTest < Minitest::Test
  def setup
    @service = ForgeBuild::Services::MasonryObjectService.new
  end

  def test_calculates_wall_quantities_and_division_metadata
    attributes = @service.attributes('cmu_wall', 240, 8, 96, 48)
    assert_equal '04', attributes[:csi_division]
    assert_equal 'wall', attributes[:builder]
    assert_equal 2, attributes[:schema_version]
    assert_equal '04 22 00', attributes[:cost_code]
    assert_equal 23_040.0, attributes[:quantities][:area_sq_in]
    assert_equal 184_320.0, attributes[:quantities][:volume_cu_in]
    assert_equal 6, attributes[:quantities][:reinforcing_locations]
  end

  def test_rejects_unsupported_types
    assert_raises(ArgumentError) { @service.attributes('wood_wall', 120, 8, 96) }
  end

  def test_supports_every_masonry_builder_capability
    expected = %w[cmu_wall brick_wall brick_veneer stone_veneer pilaster control_joint lintel
                  bond_beam grouted_cells reinforcing]
    assert_equal expected, ForgeBuild::Services::MasonryObjectService::TYPES
  end
end
