# frozen_string_literal: true

require 'json'
require_relative 'version'
require_relative 'core/container'
require_relative 'core/module_registry'
require_relative 'services/settings_service'
require_relative 'project/project'
require_relative 'ui/main_dialog'
require_relative 'commands/register_commands'

module ForgeBuild
  # Owns application startup and dependency registration.
  class Application
    attr_reader :container, :modules

    def initialize
      @container = Core::Container.new
      @modules = Core::ModuleRegistry.new
    end

    # Registers services before any user interface is created.
    def boot
      container.register(:settings) { Services::SettingsService.new }
      container.register(:main_dialog) { UI::MainDialog.new(container: container, modules: modules) }
      Commands::RegisterCommands.call(container: container)
      self
    end
  end

  def self.application
    @application ||= Application.new.boot
  end
end

ForgeBuild.application
