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
require_relative 'geometry/floor_assembly'
require_relative 'geometry/wall_assembly'
require_relative 'geometry/roof_assembly'
require_relative 'services/settings_service'
require_relative 'services/update_service'
require_relative 'services/concrete_object_service'
require_relative 'builders/floor/catalog'
require_relative 'services/floor_object_service'
require_relative 'services/masonry_object_service'
require_relative 'builders/wall/catalog'
require_relative 'services/wall_object_service'
require_relative 'services/wall_editing_service'
require_relative 'builders/roof/catalog'
require_relative 'services/roof_object_service'
require_relative 'services/roof_editing_service'
require_relative 'services/display_service'
require_relative 'services/material_tag_service'
require_relative 'services/migration_service'
require_relative 'services/preset_service'
require_relative 'services/project_store'
require_relative 'services/assembly_service'
require_relative 'services/information_service'
require_relative 'services/export_service'
require_relative 'services/drawing_service'
require_relative 'services/recognition_service'
require_relative 'services/drawing_comparison_service'
require_relative 'observers/selection_observer'
require_relative 'tools/inference_support'
require_relative 'tools/assembly_push_pull_tool'
require_relative 'tools/concrete_rectangle_tool'
require_relative 'tools/floor_placement_tool'
require_relative 'tools/masonry_line_tool'
require_relative 'tools/wall_placement_tool'
require_relative 'tools/roof_placement_tool'
require_relative 'tools/drawing_calibration_tool'
require_relative 'tools/drawing_trace_tool'
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
      container.register(:floor_objects) { Services::FloorObjectService.new(materials: container.resolve(:materials)) }
      container.register(:masonry_objects) { Services::MasonryObjectService.new }
      container.register(:wall_objects) { Services::WallObjectService.new(materials: container.resolve(:materials)) }
      container.register(:wall_editing) { Services::WallEditingService.new(regeneration: container.resolve(:regeneration)) }
      container.register(:roof_objects) { Services::RoofObjectService.new(materials: container.resolve(:materials)) }
      container.register(:roof_editing) { Services::RoofEditingService.new(regeneration: container.resolve(:regeneration)) }
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
      container.register(:information) { Services::InformationService.new }
      container.register(:exports) { Services::ExportService.new(information: container.resolve(:information)) }
      container.register(:drawings) { Services::DrawingService.new }
      container.register(:recognition) { Services::RecognitionService.new }
      container.register(:drawing_comparison) { Services::DrawingComparisonService.new }
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
        service.register(builder: :floor, object_type: type) { |**args| container.resolve(:floor_objects).regenerate(**args) }
      end
      (Builders::Floor::Catalog::SYSTEMS.keys.map(&:to_s) - %w[slab_on_grade equipment_pad]).each do |type|
        service.register(builder: :floor, object_type: type) { |**args| container.resolve(:floor_objects).regenerate(**args) }
      end
      Builders::Wall::Catalog::SYSTEMS.keys.each do |type|
        service.register(builder: :wall, object_type: type) { |**args| container.resolve(:wall_objects).regenerate(**args) }
      end
      Builders::Roof::Catalog::SYSTEMS.keys.each do |type|
        service.register(builder: :roof, object_type: type) { |**args| container.resolve(:roof_objects).regenerate(**args) }
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
                       divisions: %w[03 05 06 07 08 10 22],
                       description: 'Commercial low-slope and specialty roofs, framing, layers, openings, and drainage.') do
        Builders::Roof::Builder.new(container: container)
      end
    end
  end

  def self.application
    @application ||= Application.new.boot
  end
end

ForgeBuild.application
