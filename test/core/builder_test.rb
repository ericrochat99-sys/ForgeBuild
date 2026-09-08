# frozen_string_literal: true
require_relative '../test_helper'
require 'core/builder'
class BuilderTest < Minitest::Test
  class ExampleBuilder < ForgeBuild::Core::Builder
    def id = :example
    def name = 'Example Builder'
    def divisions = ['00']
    def tools = [Tool.new(id: :sample, name: 'Sample', description: 'Sample tool')]
  end
  def test_serializes_workspace_contract
    payload = ExampleBuilder.new(container: Object.new).workspace_payload
    assert_equal :example, payload[:id]
    assert_equal :sample, payload[:tools].first[:id]
    assert_equal ['00'], payload[:divisions]
  end
  def test_rejects_unknown_tool
    assert_raises(KeyError) { ExampleBuilder.new(container: Object.new).tool(:missing) }
  end
end
