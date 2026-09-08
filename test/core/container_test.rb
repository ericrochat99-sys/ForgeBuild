# frozen_string_literal: true

require_relative '../test_helper'
require 'core/container'

class ContainerTest < Minitest::Test
  def test_resolves_and_memoizes_service
    container = ForgeBuild::Core::Container.new
    container.register(:value) { Object.new }
    assert_same container.resolve(:value), container.resolve(:value)
  end

  def test_unknown_service_raises
    assert_raises(KeyError) { ForgeBuild::Core::Container.new.resolve(:missing) }
  end
end
