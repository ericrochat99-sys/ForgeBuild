# frozen_string_literal: true

module ForgeBuild
  module Tools
    class RoofPlacementTool
      include InferenceSupport
      def initialize(service:, object_type:, kind:, options: {})
        @service, @object_type, @kind, @options = service, object_type, kind, options
        @input = ::Sketchup::InputPoint.new
      end
      def activate
        @origin = nil
        Sketchup.status_text = @kind == :point ? 'Click to place the roof accessory.' : 'Click the first roof point.'
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
          create_between(@origin, inference_position)
          reset(view)
        else
          @origin = inference_position
          remember_inference_anchor
          Sketchup.status_text = %i[area layer].include?(@kind) ? 'Click opposite roof corner, or type width,length.' : 'Click the end of the run, or type length.'
        end
      end
      def onUserText(text, view)
        return unless @origin
        if %i[area layer].include?(@kind)
          values = text.split(/[x,;]/i).map(&:strip)
          raise ArgumentError, 'Enter width,length' unless values.length == 2
          create(origin: @origin, width: values[0].to_l, length: values[1].to_l)
        else
          length = text.to_l
          direction = @input.valid? ? (inference_position - @origin).normalize : X_AXIS
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

        view.drawing_color = '#536373'
        view.line_width = 2
        if %i[area layer].include?(@kind)
          p = inference_position
          preview = [@origin, [p.x, @origin.y, @origin.z], p, [@origin.x, p.y, @origin.z]]
          fill = ::Sketchup::Color.new('#536373')
          fill.alpha = 45
          view.drawing_color = fill
          view.draw(::GL_POLYGON, preview)
          view.drawing_color = '#536373'
          view.draw(::GL_LINE_LOOP, preview)
        elsif @kind == :line
          draw_linear_assembly_preview(view, @origin, inference_position, @options.fetch(:width, 6.0), '#536373')
        else
          view.draw(::GL_LINES, [@origin, inference_position])
        end
        draw_placement_cursor(view, @origin, '#d1492e')
        draw_inference_point(view)
      end
      private
      def create_between(origin, endpoint)
        if %i[area layer].include?(@kind)
          adjusted = ::Geom::Point3d.new([origin.x, endpoint.x].min, [origin.y, endpoint.y].min, origin.z)
          create(origin: adjusted, width: (endpoint.x - origin.x).abs, length: (endpoint.y - origin.y).abs)
        else
          create(origin: origin, endpoint: endpoint)
        end
      end
      def create(arguments) = @service.create(**{ model: Sketchup.active_model, object_type: @object_type }.merge(@options).merge(arguments))
      def reset(view)
        @origin = nil
        clear_inference
        view.invalidate
        Sketchup.status_text = 'Click the first point of the next roof object. Press Esc to finish.'
      end
    end
  end
end
