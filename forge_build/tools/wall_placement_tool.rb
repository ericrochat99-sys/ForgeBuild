# frozen_string_literal: true

module ForgeBuild
  module Tools
    class WallPlacementTool
      include InferenceSupport
      def initialize(service:, object_type:, kind:, options: {})
        @service, @object_type, @kind, @options = service, object_type, kind, options
        @input = ::Sketchup::InputPoint.new
        @wall_alignment = initial_wall_alignment
      end
      def activate
        @origin = nil
        Sketchup.status_text = point_kind? ? 'Click to place the wall opening or accessory.' : alignment_prompt('Click the start of the wall run.')
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
          create_wall_run(@origin, controlled_position(@origin))
          reset(view)
        else
          @origin = inference_position
          remember_inference_anchor
          Sketchup.status_text = alignment_prompt('Click the end of the wall run, or type a length and press Enter.')
        end
      end
      def onUserText(text, view)
        return unless @origin && !point_kind?
        length = text.to_l
        endpoint = controlled_position(@origin)
        direction = @input.valid? ? (endpoint - @origin).normalize : X_AXIS
        create_wall_run(@origin, @origin.offset(direction, length))
        reset(view)
      rescue StandardError => error
        ::UI.messagebox(error.message)
      end
      def draw(view)
        return unless @input.valid?

        if @origin && !point_kind?
          thickness = wall_thickness
          endpoint = controlled_position(@origin)
          draw_linear_assembly_preview(view, @origin, endpoint, thickness, '#a85d38', effective_alignment)
          draw_placement_cursor(view, @origin, '#d1492e')
        else
          draw_placement_cursor(view, inference_position, '#d1492e')
        end
        draw_inference_point(view)
      end

      def getExtents
        bounds = ::Geom::BoundingBox.new
        bounds.add(@origin) if @origin
        bounds.add(controlled_position(@origin)) if @input.valid?
        bounds
      end
      def onKeyDown(key, repeat, flags, view)
        if key == SHIFT_KEY && !point_kind?
          return if repeat.to_i > 1

          @wall_alignment = { center: :left, left: :right, right: :center }.fetch(@wall_alignment)
          Sketchup.status_text = alignment_prompt(@origin ? 'Click the end of the wall run, or type a length.' : 'Click the start of the wall run.')
          view.invalidate
          return
        end
        super
      end

      private
      def wall_thickness = @options.fetch(:thickness, @options.fetch('thickness', 6.0))
      def create_wall_run(origin, endpoint)
        adjusted_origin, adjusted_endpoint = aligned_run(origin, endpoint, wall_thickness, effective_alignment)
        create(origin: adjusted_origin, endpoint: adjusted_endpoint, placement_alignment: effective_alignment.to_s)
      end
      def alignment_prompt(message)
        snap = truthy_option(:snap_to_angle, true) ? " Snap: #{numeric_option(:snap_angle, 45).to_i}°" : ' Snap: free'
        "#{message} Placement: #{effective_alignment.to_s.capitalize} (tap Shift to change).#{snap}"
      end
      def initial_wall_alignment
        requested = option_value(:snap_alignment, 'automatic').to_s
        %w[center left right].include?(requested) ? requested.to_sym : :center
      end
      def effective_alignment
        requested = option_value(:snap_alignment, 'automatic').to_s
        %w[center left right].include?(requested) ? requested.to_sym : @wall_alignment
      end
      def point_kind? = %i[opening point].include?(@kind)
      def create(arguments) = @service.create(**{ model: Sketchup.active_model, object_type: @object_type }.merge(@options).merge(arguments))
      def reset(view)
        @origin = nil
        clear_inference
        view.invalidate
        Sketchup.status_text = alignment_prompt('Click the start of the next wall run. Press Esc to finish.')
      end
    end
  end
end
