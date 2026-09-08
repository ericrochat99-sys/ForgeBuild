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
        instance
      end

      def publish_bootstrap(instance)
        payload = { version: ForgeBuild::VERSION, modules: @modules.entries.map(&:name) }
        instance.execute_script("ForgeBuild.bootstrap(#{JSON.generate(payload)})")
      end
    end
  end
end
