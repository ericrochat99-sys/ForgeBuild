# frozen_string_literal: true

module ForgeBuild
  module Tools
    class WallPlacementTool
      include InferenceSupport
      def initialize(service:, object_type:, kind:, options: {})
        @service, @object_type, @kind, @options = service, object_type, kind, options
        @input = ::Sketchup::InputPoint.new
      end
      def activate
        @origin = nil
        Sketchup.status_text = point_kind? ? 'Click to place the wall opening or accessory.' : 'Click the start of the wall run.'
      end
      def onMouseMove(_flags, x, y, view)
        pick_with_inference(view, x, y)
        view.invalidate
      end
      def onLButtonDown(_flags, x, y, view)
        pick_with_inference(view, x, y)
        return unless @input.valid?
        if point_kind?
          create(origin: inference_position)
        elsif @origin
          create(origin: @origin, endpoint: inference_position)
          reset(view)
        else
          @origin = inference_position
          remember_inference_anchor
          Sketchup.status_text = 'Click the end of the wall run, or type a length and press Enter.'
        end
      end
      def onUserText(text, view)
        return unless @origin && !point_kind?
        length = text.to_l
        direction = @input.valid? ? (inference_position - @origin).normalize : X_AXIS
        create(origin: @origin, endpoint: @origin.offset(direction, length))
        reset(view)
      rescue StandardError => error
        ::UI.messagebox(error.message)
      end
      def draw(view)
        return unless @input.valid?

        if @origin && !point_kind?
          thickness = @options.fetch(:thickness, @options.fetch('thickness', 6.0))
          draw_linear_assembly_preview(view, @origin, inference_position, thickness, '#a85d38')
          draw_placement_cursor(view, @origin, '#d1492e')
        else
          draw_placement_cursor(view, inference_position, '#d1492e')
        end
        draw_inference_point(view)
      end

      def getExtents
        bounds = ::Geom::BoundingBox.new
        bounds.add(@origin) if @origin
        bounds.add(inference_position) if @input.valid?
        bounds
      end
      private
      def point_kind? = %i[opening point].include?(@kind)
      def create(arguments) = @service.create(**{ model: Sketchup.active_model, object_type: @object_type }.merge(@options).merge(arguments))
      def reset(view)
        @origin = nil
        clear_inference
        view.invalidate
        Sketchup.status_text = 'Click the start of the next wall run. Press Esc to finish.'
      end
    end
  end
end
