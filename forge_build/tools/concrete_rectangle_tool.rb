# frozen_string_literal: true

module ForgeBuild
  module Tools
    # Native click-drag placement tool for rectangular concrete objects.
    class ConcreteRectangleTool
      def initialize(service:, object_type:, thickness:)
        @service = service
        @object_type = object_type
        @thickness = thickness
        @input = ::Sketchup::InputPoint.new
      end

      def activate
        @origin = nil
        Sketchup.status_text = 'Click the first corner of the concrete object.'
      end

      def onMouseMove(_flags, x, y, view)
        @input.pick(view, x, y)
        view.tooltip = @input.tooltip if @input.valid?
        view.invalidate
      end

      def onLButtonDown(_flags, x, y, view)
        @input.pick(view, x, y)
        return unless @input.valid?

        if @origin
          create_from(@origin, @input.position)
          reset(view)
        else
          @origin = @input.position
          Sketchup.status_text = 'Click the opposite corner, or type width,length and press Enter.'
        end
      end

      def onUserText(text, view)
        return unless @origin

        values = text.split(/[x,;]/i).map(&:strip)
        raise ArgumentError, 'Enter width,length (example: 10\',20\')' unless values.length == 2

        width, length = values.map(&:to_l)
        create_dimensions(@origin, width, length)
        reset(view)
      rescue StandardError => error
        ::UI.messagebox(error.message)
      end

      def draw(view)
        return unless @origin && @input.valid?

        point = @input.position
        preview = rectangle_points(@origin, point.x - @origin.x, point.y - @origin.y)
        view.drawing_color = '#A77747'
        view.line_width = 2
        view.draw(::GL_LINE_LOOP, preview)
      end

      def getExtents
        bounds = ::Geom::BoundingBox.new
        bounds.add(@origin) if @origin
        bounds.add(@input.position) if @input.valid?
        bounds
      end

      private

      def create_from(origin, opposite)
        width = opposite.x - origin.x
        length = opposite.y - origin.y
        adjusted = ::Geom::Point3d.new([origin.x, opposite.x].min, [origin.y, opposite.y].min, origin.z)
        create_dimensions(adjusted, width.abs, length.abs)
      end

      def create_dimensions(origin, width, length)
        @service.create(model: Sketchup.active_model, origin: origin, width: width, length: length,
                        thickness: @thickness, object_type: @object_type)
      end

      def rectangle_points(origin, width, length)
        [origin, origin.offset([width, 0, 0]), origin.offset([width, length, 0]), origin.offset([0, length, 0])]
      end

      def reset(view)
        @origin = nil
        view.invalidate
        Sketchup.status_text = 'Click the first corner of the next concrete object. Press Esc to finish.'
      end
    end
  end
end
