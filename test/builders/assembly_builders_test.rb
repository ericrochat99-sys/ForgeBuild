# frozen_string_literal: true

require_relative '../test_helper'
require 'core/builder'
require 'builders/floor/builder'
require 'builders/wall/builder'
require 'builders/roof/builder'

class AssemblyBuildersTest < Minitest::Test
  def setup
    @container = Object.new
  end

  def test_primary_builders_have_stable_assembly_identities
    builders = [
      ForgeBuild::Builders::Floor::Builder.new(container: @container),
      ForgeBuild::Builders::Wall::Builder.new(container: @container),
      ForgeBuild::Builders::Roof::Builder.new(container: @container)
    ]

    assert_equal %i[floor wall roof], builders.map(&:id)
    assert_equal ['Floor Builder', 'Wall Builder', 'Roof Builder'], builders.map(&:name)
  end

  def test_existing_tools_moved_to_correct_assemblies
    floor = ForgeBuild::Builders::Floor::Builder.new(container: @container)
    wall = ForgeBuild::Builders::Wall::Builder.new(container: @container)
    roof = ForgeBuild::Builders::Roof::Builder.new(container: @container)

    assert_includes floor.tools.map(&:id), :slab_on_grade
    assert_includes floor.tools.map(&:id), :steel_joist
    assert_includes floor.tools.map(&:id), :floor_from_face
    assert_includes wall.tools.map(&:id), :cmu_wall
    assert_includes wall.tools.map(&:id), :brick_veneer
    assert_includes wall.tools.map(&:id), :metal_stud_wall
    assert_includes wall.tools.map(&:id), :door_opening
    assert_includes roof.tools.map(&:id), :low_slope_roof
    assert_includes roof.tools.map(&:id), :steel_joist
    assert_includes roof.tools.map(&:id), :roof_drain
  end
end
