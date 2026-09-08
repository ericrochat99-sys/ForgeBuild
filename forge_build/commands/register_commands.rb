# frozen_string_literal: true

module ForgeBuild
  module Commands
    # Installs menus and toolbar commands exactly once.
    module RegisterCommands
      module_function

      # Registers ForgeBuild's initial application command.
      def call(container:)
        return if @registered

        command = ::UI::Command.new('Open ForgeBuild') { container.resolve(:main_dialog).show }
        command.tooltip = 'Open ForgeBuild'
        command.status_bar_text = 'Open the ForgeBuild workspace'
        ::UI.menu('Extensions').add_item(command)

        toolbar = ::UI::Toolbar.new('ForgeBuild')
        toolbar.add_item(command)
        toolbar.restore
        @registered = true
      end
    end
  end
end
