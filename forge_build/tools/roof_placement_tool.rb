# frozen_string_literal: true

module ForgeBuild
  module Tools
    class RoofPlacementTool
      def initialize(service:, object_type:, kind:, options: {})
        @service, @object_type, @kind, @options = service, object_type, kind, options
        @input = ::Sketchup::InputPoint.new
      end
      def activate
        @origin = nil
        Sketchup.status_text = @kind == :point ? 'Click to place the roof accessory.' : 'Click the first roof point.'
      end
      def onMouseMove(_flags, x, y, view)
        @input.pick(view, x, y)
        view.tooltip = @input.tooltip if @input.valid?
        view.invalidate
      end
      def onLButtonDown(_flags, x, y, view)
        @input.pick(view, x, y)
        return unless @input.valid?
        if @kind == :point
          create(origin: @input.position)
        elsif @origin
          create_between(@origin, @input.position)
          reset(view)
        else
          @origin = @input.position
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
          direction = @input.valid? ? (@input.position - @origin).normalize : X_AXIS
          create(origin: @origin, endpoint: @origin.offset(direction, length))
        end
        reset(view)
      rescue StandardError => error
        ::UI.messagebox(error.message)
      end
      def draw(view)
        return unless @origin && @input.valid?
        view.drawing_color = '#536373'
        view.line_width = 2
        if %i[area layer].include?(@kind)
          p = @input.position
          view.draw(::GL_LINE_LOOP, [@origin, [p.x, @origin.y, @origin.z], p, [@origin.x, p.y, @origin.z]])
        else
          view.draw(::GL_LINES, [@origin, @input.position])
        end
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
        view.invalidate
        Sketchup.status_text = 'Click the first point of the next roof object. Press Esc to finish.'
      end
    end
  end
end
