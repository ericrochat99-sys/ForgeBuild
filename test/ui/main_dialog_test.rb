# frozen_string_literal: true

require_relative '../test_helper'
require 'json'

module ForgeBuild
  VERSION = 'test' unless const_defined?(:VERSION)
end

require 'ui/main_dialog'

class MainDialogTest < Minitest::Test
  FakeDialog = Struct.new(:hidden) do
    def hide
      self.hidden = true
    end
  end

  class FakeBuilder
    attr_reader :activation

    def activate_tool(tool_id, options)
      @activation = [tool_id, options]
    end
  end

  class FakeModules
    attr_reader :builder

    def initialize
      @builder = FakeBuilder.new
    end

    def build(_id)
      @builder
    end
  end

  def test_hides_reusable_dialog_after_tool_activation
    modules = FakeModules.new
    dialog = FakeDialog.new(false)
    subject = ForgeBuild::UI::MainDialog.new(container: Object.new, modules: modules)
    subject.define_singleton_method(:dialog) { dialog }

    subject.send(:activate_tool, 'masonry', 'cmu_wall', { 'height' => '96' })

    assert_equal ['cmu_wall', { 'height' => '96' }], modules.builder.activation
    assert_equal true, dialog.hidden
  end
end
