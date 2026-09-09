# frozen_string_literal: true

module ForgeBuild
  module Commands
    # Installs menus and toolbar commands exactly once.
    module RegisterCommands
      module_function

      def call(container:)
        return if @registered

        commands = build_commands(container)
        menu = ::UI.menu('Extensions').add_submenu('ForgeBuild')
        commands.each_value { |command| menu.add_item(command) }

        toolbar = ::UI::Toolbar.new('ForgeBuild')
        %i[open edit regenerate move display copy delete].each { |id| toolbar.add_item(commands.fetch(id)) }
        toolbar.restore
        install_context_menu(container)
        @registered = true
      end

      def build_commands(container)
        assemblies = -> { container.resolve(:assemblies) }
        selected = -> { assemblies.call.selected }
        definitions = {
          open: ['Open ForgeBuild', 'Open the ForgeBuild workspace', -> { container.resolve(:main_dialog).show }],
          edit: ['Edit Assembly', 'Edit the selected ForgeBuild assembly', -> { container.resolve(:main_dialog).show_inspector }],
          regenerate: ['Regenerate Assembly', 'Rebuild selected assembly geometry', -> { assemblies.call.regenerate(selected.call) }],
          move: ['Move Assembly', 'Move the selected assembly', -> { Sketchup.send_action('selectMoveTool:') }],
          copy: ['Copy Assembly', 'Copy the selected assembly', -> { assemblies.call.copy(selected.call) }],
          delete: ['Delete Assembly', 'Delete the selected assembly', -> { assemblies.call.delete(selected.call) }],
          display: ['Cycle Display Mode', 'Cycle 2D, simplified, and detailed display', lambda {
            entity = selected.call
            current = Models::ParametricObject.read(entity).fetch(:display_mode, 'detailed')
            modes = Services::DisplayService::MODES
            assemblies.call.set_display(entity, modes[(modes.index(current) + 1) % modes.length])
          }]
        }
        definitions.each_with_object({}) do |(id, (name, help, action)), result|
          result[id] = ::UI::Command.new(name, &action).tap do |command|
            command.tooltip = name
            command.status_bar_text = help
            icon = File.expand_path("../icons/#{id}.svg", __dir__)
            command.small_icon = icon if command.respond_to?(:small_icon=)
            command.large_icon = icon if command.respond_to?(:large_icon=)
          end
        end
      end

      def install_context_menu(container)
        ::UI.add_context_menu_handler do |menu|
          entity = container.resolve(:assemblies).selected
          next unless entity
          submenu = menu.add_submenu('ForgeBuild Assembly')
          submenu.add_item('Edit') { container.resolve(:main_dialog).show_inspector }
          submenu.add_item('Regenerate') { container.resolve(:assemblies).regenerate(entity) }
          display = submenu.add_submenu('Display Mode')
          Services::DisplayService::MODES.each { |mode| display.add_item(mode.capitalize) { container.resolve(:assemblies).set_display(entity, mode) } }
          submenu.add_separator
          submenu.add_item('Move') { Sketchup.send_action('selectMoveTool:') }
          submenu.add_item('Copy') { container.resolve(:assemblies).copy(entity) }
          submenu.add_item('Delete') { container.resolve(:assemblies).delete(entity) }
          if Models::ParametricObject.read(entity)[:builder] == 'wall'
            wall_menu = submenu.add_submenu('Wall Editing')
            wall_menu.add_item('Stretch') { prompt_wall_value('New wall length', entity) { |value| container.resolve(:wall_editing).stretch(entity, value) } }
            wall_menu.add_item('Split') { prompt_wall_value('Split distance from start', entity) { |value| container.resolve(:wall_editing).split(entity, value) } }
            wall_menu.add_item('Offset Copy') { prompt_wall_value('Offset distance', entity) { |value| container.resolve(:wall_editing).offset(entity, value) } }
            wall_menu.add_item('Join Selected Walls') { container.resolve(:wall_editing).join(container.resolve(:wall_editing).walls) }
            wall_menu.add_item('Connect Selected Walls') { container.resolve(:wall_editing).connect(container.resolve(:wall_editing).walls) }
            wall_menu.add_item('Align Selected Walls') { container.resolve(:wall_editing).align(container.resolve(:wall_editing).walls) }
            wall_menu.add_item('Renumber Walls') { ::UI.messagebox("Renumbered #{container.resolve(:wall_editing).renumber} walls.") }
            wall_menu.add_item('Wall Schedule Summary') { ::UI.messagebox("Wall schedule contains #{container.resolve(:wall_editing).schedule.length} assemblies.") }
          end
        end
      end

      def prompt_wall_value(label, entity)
        value = ::UI.inputbox([label], ['12\''], 'ForgeBuild Wall Editing')
        yield value.first.to_l if value
      rescue StandardError => error
        ::UI.messagebox(error.message)
      end
    end
  end
end
