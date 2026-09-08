# frozen_string_literal: true

require 'json'
require_relative 'version'
require_relative 'core/container'
require_relative 'core/module_registry'
require_relative 'core/builder'
require_relative 'models/parametric_object'
require_relative 'geometry/rectangular_prism'
require_relative 'services/settings_service'
require_relative 'services/update_service'
require_relative 'services/concrete_object_service'
require_relative 'tools/concrete_rectangle_tool'
require_relative 'builders/concrete/builder'
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
      container.register(:updater) { Services::UpdateService.new(current_version: VERSION) }
      container.register(:concrete_objects) { Services::ConcreteObjectService.new }
      container.register(:main_dialog) { UI::MainDialog.new(container: container, modules: modules) }
      register_builders
      Commands::RegisterCommands.call(container: container)
      self
    end

    private

    def register_builders
      modules.register(id: :concrete, name: 'Concrete Builder', version: VERSION, division: '03',
                       description: 'Parametric concrete foundations, slabs, pads, curbs, and stairs.') do
        Builders::Concrete::Builder.new(container: container)
      end
    end
  end

  def self.application
    @application ||= Application.new.boot
  end
end

ForgeBuild.application
