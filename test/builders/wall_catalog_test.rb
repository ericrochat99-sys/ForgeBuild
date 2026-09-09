# frozen_string_literal: true

require_relative '../test_helper'
require 'builders/wall/catalog'

class WallCatalogTest < Minitest::Test
  def test_covers_commercial_systems_layers_and_openings
    systems = ForgeBuild::Builders::Wall::Catalog::SYSTEMS
    %i[cmu_wall reinforced_cmu concrete_wall metal_stud_wall shaft_wall structural_stud_wall
       insulated_metal_panel tilt_up_panel precast_panel icf_wall sip_wall storefront_placeholder
       exterior_sheathing air_barrier continuous_insulation brick_veneer metal_panel gypsum_board
       door_opening borrowed_lite storefront_opening window_opening louver_opening overhead_door
       lintel bond_beam control_joint head_joint].each do |type|
      assert systems.key?(type), "missing #{type}"
    end
  end

  def test_all_wall_catalog_entries_have_cost_codes
    ForgeBuild::Builders::Wall::Catalog::SYSTEMS.each_value do |definition|
      assert_match(/\A\d{2} \d{2} \d{2}\z/, definition.fetch(5))
    end
  end
end
