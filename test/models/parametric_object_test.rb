# frozen_string_literal: true
require_relative '../test_helper'
require 'json'
require 'models/parametric_object'
class ParametricObjectTest < Minitest::Test
  class Entity
    def initialize = @data = {}
    def set_attribute(dictionary, key, value) = @data[[dictionary, key]] = value
    def get_attribute(dictionary, key) = @data[[dictionary, key]]
  end
  def test_round_trips_structured_metadata
    entity = Entity.new
    ForgeBuild::Models::ParametricObject.write(entity, builder: 'concrete', dimensions: { width: 120.0 })
    result = ForgeBuild::Models::ParametricObject.read(entity)
    assert_equal 'concrete', result[:builder]
    assert_equal({ 'width' => 120.0 }, result[:dimensions])
    assert ForgeBuild::Models::ParametricObject.forge_build?(entity)
  end
  def test_rejects_unknown_fields
    assert_raises(ArgumentError) { ForgeBuild::Models::ParametricObject.write(Entity.new, unsafe: true) }
  end
end
