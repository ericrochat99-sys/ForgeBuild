# frozen_string_literal: true
require_relative '../test_helper'
require 'json'
require 'models/parametric_object'
require 'services/migration_service'
class MigrationServiceTest < Minitest::Test
  class Entity
    def initialize = @data = {}
    def set_attribute(dictionary, key, value) = @data[[dictionary, key]] = value
    def get_attribute(dictionary, key) = @data[[dictionary, key]]
  end
  def test_migrates_legacy_builder_and_parameters
    entity = Entity.new
    ForgeBuild::Models::ParametricObject.write(entity, builder: 'masonry', object_type: 'cmu_wall', dimensions: { length: 120 })
    result = ForgeBuild::Services::MigrationService.new.migrate(entity)
    assert_equal 'wall', result[:builder]
    assert_equal ForgeBuild::Models::ParametricObject::SCHEMA_VERSION, result[:schema_version]
    assert_equal({ 'length' => 120 }, result[:parameters])
  end
end
