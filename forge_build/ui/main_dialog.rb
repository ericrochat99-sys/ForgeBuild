# frozen_string_literal: true

module ForgeBuild
  module UI
    # Owns the primary HtmlDialog and its Ruby-to-JavaScript boundary.
    class MainDialog
      WIDTH = 420
      HEIGHT = 680

      def initialize(container:, modules:)
        @container = container
        @modules = modules
      end

      # Opens or focuses the ForgeBuild workspace.
      def show
        dialog.show
      end

      private

      def dialog
        @dialog ||= build_dialog
      end

      def build_dialog
        instance = ::UI::HtmlDialog.new(
          dialog_title: "ForgeBuild #{ForgeBuild::VERSION}",
          preferences_key: 'ForgeBuild.MainDialog',
          scrollable: true,
          resizable: true,
          width: WIDTH,
          height: HEIGHT,
          style: ::UI::HtmlDialog::STYLE_DIALOG
        )
        instance.set_file(File.expand_path('../html/main.html', __dir__))
        instance.set_on_closed { @dialog = nil }
        instance.add_action_callback('ready') { |_context| publish_bootstrap(instance) }
        instance.add_action_callback('check_for_updates') { |_context| check_for_updates(instance) }
        instance.add_action_callback('install_update') { |_context| install_available_update(instance) }
        instance.add_action_callback('open_builder') { |_context, id| open_builder(instance, id) }
        instance.add_action_callback('activate_tool') do |_context, builder_id, tool_id, options|
          activate_tool(builder_id, tool_id, options)
        end
        instance
      end

      def publish_bootstrap(instance)
        payload = { version: ForgeBuild::VERSION, modules: @modules.entries.map(&:to_h) }
        instance.execute_script("ForgeBuild.bootstrap(#{JSON.generate(payload)})")
      end

      def open_builder(instance, id)
        payload = @modules.build(id).workspace_payload
        instance.execute_script("ForgeBuild.openBuilder(#{JSON.generate(payload)})")
      rescue KeyError => error
        instance.execute_script("ForgeBuild.showError(#{JSON.generate(error.message)})")
      end

      def activate_tool(builder_id, tool_id, options)
        @modules.build(builder_id).activate_tool(tool_id, options || {})
        dialog.hide
      rescue StandardError => error
        ::UI.messagebox("ForgeBuild could not start the tool: #{error.message}")
      end

      def check_for_updates(instance)
        @container.resolve(:updater).check do |result|
          @available_update = result if result[:status] == 'available'
          instance.execute_script("ForgeBuild.updateResult(#{JSON.generate(result)})")
        end
      end

      def install_available_update(instance)
        return unless @available_update

        instance.execute_script('ForgeBuild.updateInstalling()')
        @container.resolve(:updater).install(@available_update) do |result|
          instance.execute_script("ForgeBuild.installResult(#{JSON.generate(result)})")
          @available_update = nil if result[:status] == 'installed'
        end
      end
    end
  end
end
