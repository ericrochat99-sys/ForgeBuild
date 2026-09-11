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
        @wall_alignment = :center
      end

      def activate
        @origin = nil
        Sketchup.status_text = alignment_prompt('Click the start of the masonry run.')
      end

      def onMouseMove(_flags, x, y, view)
        pick_with_inference(view, x, y)
        view.invalidate
      end

      def onLButtonDown(_flags, x, y, view)
        pick_with_inference(view, x, y)
        return unless @input.valid?

        if @origin
          create_aligned_run(@origin, inference_position)
          reset(view)
        else
          @origin = inference_position
          remember_inference_anchor
          Sketchup.status_text = alignment_prompt('Click the end of the masonry run, or type its length and press Enter.')
        end
      end

      def onUserText(text, view)
        return unless @origin

        length = text.to_l
        direction = preview_direction
        create_aligned_run(@origin, @origin.offset(direction, length))
        reset(view)
      rescue StandardError => error
        ::UI.messagebox(error.message)
      end

      def draw(view)
        return unless @input.valid?

        if @origin
          draw_linear_assembly_preview(view, @origin, inference_position, @thickness, '#9b6848', @wall_alignment)
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

      def onKeyDown(key, repeat, flags, view)
        if key == SHIFT_KEY
          return if repeat.to_i > 1

          @wall_alignment = { center: :left, left: :right, right: :center }.fetch(@wall_alignment)
          Sketchup.status_text = alignment_prompt(@origin ? 'Click the end of the masonry run, or type its length.' : 'Click the start of the masonry run.')
          view.invalidate
          return
        end
        super
      end

      private

      def create_aligned_run(origin, endpoint)
        adjusted_origin, adjusted_endpoint = aligned_run(origin, endpoint, @thickness, @wall_alignment)
        create_run(adjusted_origin, adjusted_endpoint)
      end

      def alignment_prompt(message) = "#{message} Placement: #{@wall_alignment.to_s.capitalize} (tap Shift to change)."

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
        Sketchup.status_text = alignment_prompt('Click the start of the next masonry run. Press Esc to finish.')
      end
    end
  end
end
