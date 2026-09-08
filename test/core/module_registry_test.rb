# frozen_string_literal: true

require_relative '../test_helper'
require 'core/module_registry'

class ModuleRegistryTest < Minitest::Test
  def test_registers_and_builds_module
    registry = ForgeBuild::Core::ModuleRegistry.new
    registry.register(id: :walls, name: 'Wall Builder', version: '0.1.0') { :wall_module }
    assert_equal :wall_module, registry.build(:walls)
    assert_equal ['Wall Builder'], registry.entries.map(&:name)
  end

  def test_rejects_duplicate_identifier
    registry = ForgeBuild::Core::ModuleRegistry.new
    registry.register(id: :walls, name: 'Walls', version: '1.0.0') { Object.new }
    assert_raises(ArgumentError) { registry.register(id: :walls, name: 'Other', version: '1.0.0') { Object.new } }
  end

  def test_exposes_builder_metadata
    registry = ForgeBuild::Core::ModuleRegistry.new
    registry.register(id: :floor, name: 'Floor Builder', version: '0.4.0', divisions: %w[03 05 06],
                      description: 'Floor systems') { Object.new }
    assert_equal %w[03 05 06], registry.fetch(:floor).to_h[:divisions]
  end
end
