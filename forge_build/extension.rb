# frozen_string_literal: true

require 'json'
require_relative 'version'
require_relative 'core/container'
require_relative 'core/module_registry'
require_relative 'core/builder'
require_relative 'models/parametric_object'
require_relative 'services/regeneration_service'
require_relative 'geometry/rectangular_prism'
require_relative 'services/settings_service'
require_relative 'services/update_service'
require_relative 'services/concrete_object_service'
require_relative 'services/masonry_object_service'
require_relative 'tools/concrete_rectangle_tool'
require_relative 'tools/masonry_line_tool'
require_relative 'builders/floor/builder'
require_relative 'builders/wall/builder'
require_relative 'builders/roof/builder'
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
      container.register(:masonry_objects) { Services::MasonryObjectService.new }
      container.register(:regeneration) { Services::RegenerationService.new }
      container.register(:main_dialog) { UI::MainDialog.new(container: container, modules: modules) }
      register_builders
      Commands::RegisterCommands.call(container: container)
      self
    end

    private

    def register_builders
      modules.register(id: :floor, name: 'Floor Builder', version: VERSION,
                       divisions: %w[03 05 06],
                       description: 'Slabs, framed floors, joists, beams, decks, and openings.') do
        Builders::Floor::Builder.new(container: container)
      end
      modules.register(id: :wall, name: 'Wall Builder', version: VERSION,
                       divisions: %w[03 04 05 06 07 09],
                       description: 'Framed, masonry, concrete, ICF, and SIP wall assemblies.') do
        Builders::Wall::Builder.new(container: container)
      end
      modules.register(id: :roof, name: 'Roof Builder', version: VERSION,
                       divisions: %w[05 06 07],
                       description: 'Rafters, trusses, roof layers, fascia, soffits, and drainage.') do
        Builders::Roof::Builder.new(container: container)
      end
    end
  end

  def self.application
    @application ||= Application.new.boot
  end
end

ForgeBuild.application
