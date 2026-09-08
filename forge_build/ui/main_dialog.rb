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
        instance.add_action_callback('ready') { |_context| publish_bootstrap(instance) }
        instance.add_action_callback('check_for_updates') { |_context| check_for_updates(instance) }
        instance.add_action_callback('download_update') { |_context| open_available_update }
        instance
      end

      def publish_bootstrap(instance)
        payload = { version: ForgeBuild::VERSION, modules: @modules.entries.map(&:name) }
        instance.execute_script("ForgeBuild.bootstrap(#{JSON.generate(payload)})")
      end

      def check_for_updates(instance)
        @container.resolve(:updater).check do |result|
          @available_update_url = result[:download_url] || result[:release_url] if result[:status] == 'available'
          instance.execute_script("ForgeBuild.updateResult(#{JSON.generate(result)})")
        end
      end

      def open_available_update
        ::UI.openURL(@available_update_url) if @available_update_url
      end
    end
  end
end
