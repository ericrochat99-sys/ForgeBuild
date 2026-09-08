# frozen_string_literal: true

require_relative '../test_helper'
require 'json'
require 'models/parametric_object'
require 'services/regeneration_service'

class RegenerationServiceTest < Minitest::Test
  FakeEntity = Struct.new(:attributes) do
    def get_attribute(dictionary, key)
      attributes[[dictionary, key]]
    end
  end

  def test_routes_assembly_to_registered_handler
    entity = FakeEntity.new({
      ['ForgeBuild.Object', 'builder'] => 'floor',
      ['ForgeBuild.Object', 'object_type'] => 'slab_on_grade'
    })
    called = false
    service = ForgeBuild::Services::RegenerationService.new
    service.register(builder: :floor, object_type: :slab_on_grade) do |entity:, model:, attributes:|
      called = entity && model == :model && attributes[:builder] == 'floor'
    end

    service.regenerate(entity, model: :model)
    assert called
  end

  def test_rejects_unknown_assembly_type
    entity = FakeEntity.new({
      ['ForgeBuild.Object', 'builder'] => 'roof',
      ['ForgeBuild.Object', 'object_type'] => 'gable'
    })
    assert_raises(KeyError) do
      ForgeBuild::Services::RegenerationService.new.regenerate(entity, model: :model)
    end
  end
end
