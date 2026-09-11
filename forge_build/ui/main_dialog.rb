# frozen_string_literal: true

module ForgeBuild
  module UI
    # Owns the primary HtmlDialog and its Ruby-to-JavaScript boundary.
    class MainDialog
      WIDTH = 1180
      HEIGHT = 760

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
          style: ::UI::HtmlDialog::STYLE_UTILITY
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
        instance.add_action_callback('push_pull_assembly') { |_context| activate_push_pull }
        instance.add_action_callback('set_display_mode') { |_context, mode| set_display_mode(instance, mode) }
        instance.add_action_callback('save_preset') { |_context, name, parameters, make_default| save_preset(instance, name, parameters, make_default) }
        instance.add_action_callback('apply_preset') { |_context, name| apply_preset(instance, name) }
        instance.add_action_callback('refresh_reports') { |_context, options| publish_reports(instance, options || {}) }
        instance.add_action_callback('export_reports') { |_context, options| export_reports(instance, options || {}) }
        instance.add_action_callback('import_drawing') { |_context, options| import_drawing(instance, options || {}) }
        instance.add_action_callback('browse_plan_set') { |_context| browse_plan_set(instance) }
        instance.add_action_callback('import_plan_set') { |_context, selections| import_plan_set(instance, selections || []) }
        instance.add_action_callback('set_drawing_elevation') { |_context, id, elevation| set_drawing_elevation(instance, id, elevation) }
        instance.add_action_callback('calibrate_drawing') { |_context, id| calibrate_drawing(id) }
        instance.add_action_callback('trace_drawing') { |_context, kind| trace_drawing(kind) }
        instance.add_action_callback('recognize_annotations') { |_context, text| recognize_annotations(instance, text) }
        instance.add_action_callback('compare_drawing') { |_context| compare_drawing(instance) }
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

      def activate_push_pull
        entity = @container.resolve(:assemblies).selected
        raise 'Select a ForgeBuild assembly before using Push/Pull Assembly.' unless entity

        Sketchup.active_model.select_tool(
          Tools::AssemblyPushPullTool.new(service: @container.resolve(:assemblies), entity: entity)
        )
        dialog.hide
      rescue StandardError => error
        ::UI.messagebox(error.message)
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
        payload = { version: ForgeBuild::VERSION, modules: @modules.entries.map(&:to_h),
                    drawings: @container.resolve(:drawings).registry(Sketchup.active_model) }
        instance.execute_script("ForgeBuild.bootstrap(#{JSON.generate(payload)})")
      end

      def import_drawing(instance, options)
        path = ::UI.openpanel('Import Architectural, Structural, or MEP Drawing', nil, 'Drawings|*.pdf;*.png;*.jpg;*.jpeg;*.tif;*.tiff;*.dwg;*.dxf||')
        return unless path
        drawing = @container.resolve(:drawings).import(model: Sketchup.active_model, path: path,
                                                        discipline: options['discipline'] || 'architectural',
                                                        sheet: options['sheet'] || '', revision: options['revision'] || '',
                                                        page: options['page'] || 1, elevation: options['elevation'] || 0)
        instance.execute_script("ForgeBuild.drawingImported(#{JSON.generate(drawing)})")
        start_imported_drawing_calibration(drawing)
      rescue StandardError => error
        instance.execute_script("ForgeBuild.showError(#{JSON.generate(error.message)})")
      end

      def browse_plan_set(instance)
        directory = ::UI.select_directory(title: 'Choose Folder Containing Plan PDFs')
        return unless directory

        files = Dir.children(directory).select { |name| File.extname(name).casecmp('.pdf').zero? }.sort
        raise 'No PDF files were found in the selected folder.' if files.empty?

        payload = files.map { |name| { path: File.join(directory, name), filename: name } }
        instance.execute_script("ForgeBuild.planSetFound(#{JSON.generate(payload)})")
      rescue StandardError => error
        instance.execute_script("ForgeBuild.showError(#{JSON.generate(error.message)})")
      end

      def import_plan_set(instance, selections)
        raise 'Select at least one plan to import.' if selections.empty?

        drawings = selections.map do |selection|
          @container.resolve(:drawings).import(
            model: Sketchup.active_model,
            path: selection['path'],
            discipline: selection['discipline'] || 'architectural',
            sheet: selection['sheet'] || File.basename(selection['path'], '.*'),
            revision: selection['revision'] || '',
            page: selection['page'] || 1,
            elevation: selection['elevation'] || 0
          )
        end
        @container.resolve(:drawings).focus(model: Sketchup.active_model, drawing: drawings.last)
        instance.execute_script("ForgeBuild.planSetImported(#{JSON.generate(drawings)})")
      rescue StandardError => error
        instance.execute_script("ForgeBuild.showError(#{JSON.generate(error.message)})")
      end

      def set_drawing_elevation(instance, id, elevation)
        raise 'Choose an imported plan first.' if id.to_s.strip.empty?

        drawing = @container.resolve(:drawings).set_elevation(
          model: Sketchup.active_model, id: id, elevation: elevation
        )
        instance.execute_script("ForgeBuild.drawingElevationChanged(#{JSON.generate(drawing)})")
      rescue StandardError => error
        instance.execute_script("ForgeBuild.showError(#{JSON.generate(error.message)})")
      end

      def start_imported_drawing_calibration(drawing)
        model = Sketchup.active_model
        @container.resolve(:drawings).focus(model: model, drawing: drawing)
        instance = Tools::DrawingCalibrationTool.new(service: @container.resolve(:drawings), drawing: drawing)
        model.select_tool(instance)
        dialog.hide
        Sketchup.status_text = 'Plan imported and fitted to the modeling area. Click two endpoints of a known dimension to calibrate.'
      end

      def calibrate_drawing(id = nil)
        model = Sketchup.active_model
        drawings = @container.resolve(:drawings)
        drawing = if id.to_s.strip.empty?
                    drawings.registry(model).last
                  else
                    drawings.find(model, id)
                  end
        raise 'Import a plan before starting calibration.' unless drawing

        drawings.focus(model: model, drawing: drawing)
        model.select_tool(Tools::DrawingCalibrationTool.new(service: drawings, drawing: drawing))
        dialog.hide
        Sketchup.status_text = 'Calibration active: click the first endpoint of a known dimension on the plan.'
      rescue StandardError => error
        ::UI.messagebox("ForgeBuild could not start calibration: #{error.message}")
      end

      def trace_drawing(kind)
        services = { floor: @container.resolve(:floor_objects), wall: @container.resolve(:wall_objects), roof: @container.resolve(:roof_objects) }
        Sketchup.active_model.select_tool(Tools::DrawingTraceTool.new(kind: kind, services: services))
        dialog.hide
      rescue StandardError => error
        ::UI.messagebox(error.message)
      end

      def recognize_annotations(instance, text)
        @recognized = @container.resolve(:recognition).recognize(text: text, source: 'manual/OCR')
        instance.execute_script("ForgeBuild.recognitionResult(#{JSON.generate(@recognized)})")
      rescue StandardError => error
        instance.execute_script("ForgeBuild.showError(#{JSON.generate(error.message)})")
      end

      def compare_drawing(instance)
        features = Array(@recognized && @recognized[:suggestions])
        result = @container.resolve(:drawing_comparison).compare(
          model_objects: @container.resolve(:information).collect(Sketchup.active_model), recognized_features: features)
        instance.execute_script("ForgeBuild.comparisonResult(#{JSON.generate(result)})")
      rescue StandardError => error
        instance.execute_script("ForgeBuild.showError(#{JSON.generate(error.message)})")
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
