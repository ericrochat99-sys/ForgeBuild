# frozen_string_literal: true

module ForgeBuild
  module Tools
    class DrawingCalibrationTool
      include InferenceSupport
      def initialize(service:, drawing:)
        @service, @drawing = service, drawing
        @input = ::Sketchup::InputPoint.new
      end

      def activate
        @first = nil
        Sketchup.status_text = 'Click the first point of a known drawing dimension.'
      end

      def onMouseMove(_flags, x, y, view)
        pick_with_inference(view, x, y)
        view.invalidate
      end

      def onLButtonDown(_flags, x, y, view)
        pick_with_inference(view, x, y)
        return unless @input.valid?
        if @first
          measured = (inference_position - @first).length
          response = ::UI.inputbox(['Actual dimension'], [measured.to_l.to_s], 'Calibrate Drawing')
          return unless response
          actual = response.first.to_l
          updated = @service.calibrate(model: Sketchup.active_model, id: @drawing[:id], measured_length: measured, actual_length: actual)
          entity = find_entity(Sketchup.active_model, @drawing[:entity_id])
          entity.transform!(::Geom::Transformation.scaling(@first, updated[:scale])) if entity
          Sketchup.status_text = "Drawing calibrated to scale #{updated[:scale].round(6)}."
          Sketchup.active_model.select_tool(nil)
        else
          @first = inference_position
          remember_inference_anchor
          Sketchup.status_text = 'Click the second point of the known dimension.'
        end
      end

      def draw(view)
        return unless @first && @input.valid?
        view.drawing_color = '#A77747'
        view.line_width = 3
        view.draw(::GL_LINES, [@first, inference_position])
        draw_inference_point(view)
      end

      private

      def find_entity(model, id)
        return nil unless id
        return model.find_entity_by_persistent_id(id) if model.respond_to?(:find_entity_by_persistent_id)
        model.entities.find { |entity| entity.respond_to?(:persistent_id) && entity.persistent_id == id }
      end
    end
  end
end
