# frozen_string_literal: true

module ForgeBuild
  module Tools
    # Two-click line placement tool for Division 04 masonry assemblies.
    class MasonryLineTool
      include InferenceSupport
      def initialize(service:, object_type:, thickness:, height:, cell_spacing:)
        @service = service
        @object_type = object_type
        @thickness = thickness
        @height = height
        @cell_spacing = cell_spacing
        @input = ::Sketchup::InputPoint.new
      end

      def activate
        @origin = nil
        Sketchup.status_text = 'Click the start of the masonry run.'
      end

      def onMouseMove(_flags, x, y, view)
        pick_with_inference(view, x, y)
        view.invalidate
      end

      def onLButtonDown(_flags, x, y, view)
        pick_with_inference(view, x, y)
        return unless @input.valid?

        if @origin
          create_run(@origin, inference_position)
          reset(view)
        else
          @origin = inference_position
          remember_inference_anchor
          Sketchup.status_text = 'Click the end of the masonry run, or type its length and press Enter.'
        end
      end

      def onUserText(text, view)
        return unless @origin

        length = text.to_l
        direction = preview_direction
        create_run(@origin, @origin.offset(direction, length))
        reset(view)
      rescue StandardError => error
        ::UI.messagebox(error.message)
      end

      def draw(view)
        return unless @origin && @input.valid?

        view.drawing_color = '#a85d38'
        view.line_width = 3
        view.draw(::GL_LINES, [@origin, inference_position])
        draw_inference_point(view)
      end

      def getExtents
        bounds = ::Geom::BoundingBox.new
        bounds.add(@origin) if @origin
        bounds.add(inference_position) if @input.valid?
        bounds
      end

      private

      def create_run(origin, endpoint)
        @service.create(model: Sketchup.active_model, origin: origin, endpoint: endpoint,
                        thickness: @thickness, height: @height, object_type: @object_type,
                        cell_spacing: @cell_spacing)
      end

      def preview_direction
        return X_AXIS unless @input.valid?

        vector = inference_position - @origin
        vector.length.positive? ? vector.normalize : X_AXIS
      end

      def reset(view)
        @origin = nil
        clear_inference
        view.invalidate
        Sketchup.status_text = 'Click the start of the next masonry run. Press Esc to finish.'
      end
    end
  end
end
