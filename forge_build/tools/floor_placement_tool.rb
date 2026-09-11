# frozen_string_literal: true

module ForgeBuild
  module Tools
    class FloorPlacementTool
      include InferenceSupport
      def initialize(service:, object_type:, kind:, options: {})
        @service, @object_type, @kind, @options = service, object_type, kind, options
        @input = ::Sketchup::InputPoint.new
      end

      def activate
        @origin = nil
        Sketchup.status_text = prompt(:first)
      end

      def onMouseMove(_flags, x, y, view)
        pick_with_inference(view, x, y)
        view.invalidate
      end

      def onLButtonDown(_flags, x, y, view)
        pick_with_inference(view, x, y)
        return unless @input.valid?
        if @kind == :point
          create(origin: inference_position)
        elsif @origin
          create_between(@origin, controlled_position(@origin))
          reset(view)
        else
          @origin = inference_position
          remember_inference_anchor
          Sketchup.status_text = prompt(:second)
        end
      end

      def onUserText(text, view)
        return unless @origin
        if @kind == :area
          values = text.split(/[x,;]/i).map(&:strip)
          raise ArgumentError, 'Enter width,length (example: 20\',30\')' unless values.length == 2
          create(origin: @origin, width: values[0].to_l, length: values[1].to_l)
        else
          length = text.to_l
          endpoint = controlled_position(@origin)
          direction = @input.valid? ? (endpoint - @origin).normalize : X_AXIS
          create(origin: @origin, endpoint: @origin.offset(direction, length))
        end
        reset(view)
      rescue StandardError => error
        ::UI.messagebox(error.message)
      end

      def draw(view)
        return unless @input.valid?

        unless @origin
          draw_placement_cursor(view, inference_position, '#d1492e')
          draw_inference_point(view)
          return
        end

        endpoint = controlled_position(@origin)
        view.drawing_color = '#A77747'
        view.line_width = 2
        if @kind == :area
          preview = rectangle(@origin, endpoint.x - @origin.x, endpoint.y - @origin.y)
          fill = ::Sketchup::Color.new('#A77747')
          fill.alpha = 45
          view.drawing_color = fill
          view.draw(::GL_POLYGON, preview)
          view.drawing_color = '#A77747'
          view.draw(::GL_LINE_LOOP, preview)
        elsif @kind == :linear
          draw_linear_assembly_preview(view, @origin, endpoint, @options.fetch(:width, 6.0), '#A77747')
        else
          view.draw(::GL_LINES, [@origin, endpoint])
        end
        draw_placement_cursor(view, @origin, '#d1492e')
        draw_inference_point(view)
      end

      def getExtents
        bounds = ::Geom::BoundingBox.new
        bounds.add(@origin) if @origin
        bounds.add(controlled_position(@origin)) if @input.valid?
        bounds
      end

      private

      def create_between(origin, endpoint)
        if @kind == :area
          width, length = endpoint.x - origin.x, endpoint.y - origin.y
          adjusted = ::Geom::Point3d.new([origin.x, endpoint.x].min, [origin.y, endpoint.y].min, origin.z)
          create(origin: adjusted, width: width.abs, length: length.abs)
        else
          create(origin: origin, endpoint: endpoint)
        end
      end

      def create(arguments)
        @service.create(**{ model: Sketchup.active_model, object_type: @object_type }.merge(@options).merge(arguments))
      end

      def rectangle(origin, width, length)
        [origin, origin.offset([width, 0, 0]), origin.offset([width, length, 0]), origin.offset([0, length, 0])]
      end

      def prompt(stage)
        return 'Click to place the next floor object. Press Esc to finish.' if @kind == :point
        noun = @kind == :area ? 'corner' : 'point'
        snap = truthy_option(:snap_to_angle, true) ? " Snap: #{numeric_option(:snap_angle, 45).to_i}°" : ' Snap: free'
        stage == :first ? "Click the first #{noun}.#{snap}" : "Click the second #{noun}, or type dimensions and press Enter.#{snap}"
      end

      def reset(view)
        @origin = nil
        clear_inference
        view.invalidate
        Sketchup.status_text = prompt(:first)
      end
    end
  end
end
