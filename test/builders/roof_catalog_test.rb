# frozen_string_literal: true

require_relative '../test_helper'
require 'builders/roof/catalog'

class RoofCatalogTest < Minitest::Test
  def test_covers_low_slope_sloped_structure_and_drainage
    systems = ForgeBuild::Builders::Roof::Catalog::SYSTEMS
    %i[low_slope_roof steel_roof_deck tapered_insulation tpo_membrane epdm_membrane
       gable_roof hip_roof shed_roof standing_seam steel_joist wood_rafter roof_truss
       parapet coping roof_curb roof_hatch skylight roof_drain overflow_drain scupper
       gutter downspout canopy].each { |type| assert systems.key?(type), "missing #{type}" }
  end

  def test_all_roof_catalog_entries_have_cost_codes
    ForgeBuild::Builders::Roof::Catalog::SYSTEMS.each_value do |definition|
      assert_match(/\A\d{2} \d{2} \d{2}\z/, definition.fetch(5))
    end
  end
end
