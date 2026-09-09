# frozen_string_literal: true

require_relative '../test_helper'
require 'builders/floor/catalog'

class FloorCatalogTest < Minitest::Test
  def test_covers_floor_foundation_structure_and_coordination
    systems = ForgeBuild::Builders::Floor::Catalog::SYSTEMS
    %i[slab_on_grade continuous_footing grade_beam foundation_wall steel_beam steel_joist
       metal_deck hollow_core wood_joist rectangular_opening circular_opening coordination_zone
       floor_from_face].each { |type| assert systems.key?(type), "missing #{type}" }
  end

  def test_every_system_has_a_supported_placement_kind
    kinds = ForgeBuild::Builders::Floor::Catalog::SYSTEMS.values.map(&:first).uniq
    assert_equal %i[area face linear point], kinds.sort
  end
end
