# frozen_string_literal: true

require 'json'
require 'fileutils'
require_relative 'version'
require_relative 'core/container'
require_relative 'core/module_registry'
require_relative 'core/builder'
require_relative 'models/parametric_object'
require_relative 'database/connection'
require_relative 'database/migrator'
require_relative 'services/regeneration_service'
require_relative 'geometry/rectangular_prism'
require_relative 'services/settings_service'
require_relative 'services/update_service'
require_relative 'services/concrete_object_service'
require_relative 'services/masonry_object_service'
require_relative 'services/display_service'
require_relative 'services/material_tag_service'
require_relative 'services/migration_service'
require_relative 'services/preset_service'
require_relative 'services/project_store'
require_relative 'services/assembly_service'
require_relative 'observers/selection_observer'
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
      container.register(:display) { Services::DisplayService.new }
      container.register(:materials) { Services::MaterialTagService.new }
      container.register(:migration) { Services::MigrationService.new }
      container.register(:database) { open_database }
      container.register(:presets) { Services::PresetService.new(connection: container.resolve(:database), settings: container.resolve(:settings)) }
      container.register(:projects) { Services::ProjectStore.new(connection: container.resolve(:database)) }
      container.register(:assemblies) do
        Services::AssemblyService.new(regeneration: container.resolve(:regeneration), display: container.resolve(:display),
                                      materials: container.resolve(:materials), migration: container.resolve(:migration))
      end
      container.register(:main_dialog) { UI::MainDialog.new(container: container, modules: modules) }
      register_builders
      register_regeneration
      container.resolve(:migration).migrate_model
      Commands::RegisterCommands.call(container: container)
      self
    end

    private

    def open_database
      path = File.join(Sketchup.find_support_file('Plugins'), 'ForgeBuildData', 'forgebuild.sqlite3')
      FileUtils.mkdir_p(File.dirname(path))
      connection = Database::Connection.open(path)
      Database::Migrator.new(connection).migrate
      connection
    rescue LoadError => error
      warn(error.message)
      nil
    end

    def register_regeneration
      service = container.resolve(:regeneration)
      %w[slab_on_grade equipment_pad].each do |type|
        service.register(builder: :floor, object_type: type) { |**args| container.resolve(:concrete_objects).regenerate(**args) }
      end
      Services::MasonryObjectService::TYPES.each do |type|
        service.register(builder: :wall, object_type: type) { |**args| container.resolve(:masonry_objects).regenerate(**args) }
      end
    end

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
