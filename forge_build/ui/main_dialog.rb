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
        attach_selection_observer
        publish_selection(dialog)
      end

      def show_inspector
        show
        dialog.execute_script('ForgeBuild.showInspector()')
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
        instance.add_action_callback('save_assembly') { |_context, changes| save_assembly(instance, changes || {}) }
        instance.add_action_callback('regenerate_assembly') { |_context| command(instance, :regenerate) }
        instance.add_action_callback('copy_assembly') { |_context| command(instance, :copy) }
        instance.add_action_callback('delete_assembly') { |_context| command(instance, :delete) }
        instance.add_action_callback('move_assembly') { |_context| Sketchup.send_action('selectMoveTool:') }
        instance.add_action_callback('set_display_mode') { |_context, mode| set_display_mode(instance, mode) }
        instance.add_action_callback('save_preset') { |_context, name, parameters, make_default| save_preset(instance, name, parameters, make_default) }
        instance.add_action_callback('apply_preset') { |_context, name| apply_preset(instance, name) }
        instance.add_action_callback('refresh_reports') { |_context, options| publish_reports(instance, options || {}) }
        instance.add_action_callback('export_reports') { |_context, options| export_reports(instance, options || {}) }
        instance
      end

      def attach_selection_observer
        return if @selection_observer
        @selection_observer = Observers::SelectionObserver.new { publish_selection(dialog) if @dialog }
        Sketchup.active_model.selection.add_observer(@selection_observer)
      end

      def publish_selection(instance)
        payload = @container.resolve(:assemblies).inspect
        if payload
          payload[:presets] = @container.resolve(:presets).list(builder: payload[:builder], object_type: payload[:object_type])
        end
        instance.execute_script("ForgeBuild.selectionChanged(#{JSON.generate(payload)})")
      rescue StandardError => error
        instance.execute_script("ForgeBuild.showError(#{JSON.generate(error.message)})")
      end

      def save_assembly(instance, changes)
        @container.resolve(:assemblies).edit(@container.resolve(:assemblies).selected, changes)
        publish_selection(instance)
      rescue StandardError => error
        instance.execute_script("ForgeBuild.showError(#{JSON.generate(error.message)})")
      end

      def command(instance, action)
        service = @container.resolve(:assemblies)
        service.public_send(action, service.selected)
        publish_selection(instance)
      rescue StandardError => error
        instance.execute_script("ForgeBuild.showError(#{JSON.generate(error.message)})")
      end

      def set_display_mode(instance, mode)
        service = @container.resolve(:assemblies)
        service.set_display(service.selected, mode)
        publish_selection(instance)
      end

      def save_preset(instance, name, parameters, make_default)
        attributes = @container.resolve(:assemblies).inspect
        @container.resolve(:presets).save(builder: attributes[:builder], object_type: attributes[:object_type],
                                            name: name, parameters: parameters, default: make_default)
        instance.execute_script("ForgeBuild.presetSaved(#{JSON.generate(name)})")
      rescue StandardError => error
        instance.execute_script("ForgeBuild.showError(#{JSON.generate(error.message)})")
      end

      def apply_preset(instance, name)
        attributes = @container.resolve(:assemblies).inspect
        preset = @container.resolve(:presets).list(builder: attributes[:builder], object_type: attributes[:object_type]).find { |item| item[:name] == name }
        raise KeyError, "Unknown preset: #{name}" unless preset
        @container.resolve(:assemblies).edit(@container.resolve(:assemblies).selected, 'parameters' => preset[:parameters])
        publish_selection(instance)
      rescue StandardError => error
        instance.execute_script("ForgeBuild.showError(#{JSON.generate(error.message)})")
      end

      def publish_bootstrap(instance)
        payload = { version: ForgeBuild::VERSION, modules: @modules.entries.map(&:to_h) }
        instance.execute_script("ForgeBuild.bootstrap(#{JSON.generate(payload)})")
      end

      def publish_reports(instance, options = {})
        report = @container.resolve(:information).report(model: Sketchup.active_model,
                                                          waste_factors: options['waste_factors'] || {})
        instance.execute_script("ForgeBuild.reportResult(#{JSON.generate(report)})")
      rescue StandardError => error
        instance.execute_script("ForgeBuild.showError(#{JSON.generate(error.message)})")
      end

      def export_reports(instance, options = {})
        directory = ::UI.select_directory(title: 'Export ForgeBuild Commercial Delivery Package')
        return unless directory

        path = @container.resolve(:exports).export(model: Sketchup.active_model, directory: directory, options: options)
        instance.execute_script("ForgeBuild.exportResult(#{JSON.generate(path)})")
      rescue StandardError => error
        instance.execute_script("ForgeBuild.showError(#{JSON.generate(error.message)})")
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
