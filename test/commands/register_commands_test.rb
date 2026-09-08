# frozen_string_literal: true

require_relative '../test_helper'

module UI
  class Command
    attr_accessor :tooltip, :status_bar_text
    def initialize(_name, &_block); end
  end

  class Toolbar
    def initialize(_name); end
    def add_item(_command); end
    def restore; end
  end

  def self.menu(_name)
    Object.new.tap { |menu| menu.define_singleton_method(:add_item) { |_command| } }
  end
end

module ForgeBuild
  module UI; end
end

require 'commands/register_commands'

class RegisterCommandsTest < Minitest::Test
  def test_uses_sketchup_global_ui_namespace
    container = Object.new
    assert_equal true, ForgeBuild::Commands::RegisterCommands.call(container: container)
  end
end
