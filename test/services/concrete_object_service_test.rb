# frozen_string_literal: true
require_relative '../test_helper'
require 'services/concrete_object_service'
class ConcreteObjectServiceTest < Minitest::Test
  def test_calculates_area_and_volume_metadata
    attributes = ForgeBuild::Services::ConcreteObjectService.new.attributes('slab_on_grade', 120, 240, 6)
    assert_equal 28_800.0, attributes[:quantities][:area_sq_in]
    assert_equal 172_800.0, attributes[:quantities][:volume_cu_in]
    assert_equal '03', attributes[:csi_division]
    assert_equal 'floor', attributes[:builder]
    assert_equal 2, attributes[:schema_version]
    assert_equal 6.0, attributes[:parameters][:thickness]
  end
end
