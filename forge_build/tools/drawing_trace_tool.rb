# frozen_string_literal: true

module ForgeBuild
  module Tools
    # Two-click tracing for assembly boundaries, openings, grids, and levels.
    class DrawingTraceTool
      DEFAULTS = {
        floor: ['slab_on_grade', { thickness: 4.0 }], wall: ['metal_stud_wall', { thickness: 4.875, height: 120.0 }],
        roof: ['low_slope_roof', { thickness: 6.0, pitch: 0.25 }], opening: ['door_opening', { width: 36.0, depth: 4.875, height: 84.0 }]
      }.freeze

      def initialize(kind:, services:, options: {})
        @kind, @services, @options = kind.to_sym, services, options.transform_keys(&:to_sym)
        @input = ::Sketchup::InputPoint.new
      end

      def activate
        @first = nil
        Sketchup.status_text = @kind == :opening || @kind == :level ? 'Click the drawing location.' : 'Click the first trace point.'
      end

      def onMouseMove(_flags, x, y, view)
        @input.pick(view, x, y)
        view.invalidate
      end

      def onLButtonDown(_flags, x, y, view)
        @input.pick(view, x, y)
        return unless @input.valid?
        return create_point(@input.position) if %i[opening level].include?(@kind)
        if @first
          create_between(@first, @input.position)
          @first = nil
          Sketchup.status_text = 'Trace created. Click the first point of another trace.'
        else
          @first = @input.position
          Sketchup.status_text = 'Click the second trace point.'
        end
      rescue StandardError => error
        ::UI.messagebox(error.message)
      end

      def draw(view)
        return unless @first && @input.valid?
        view.drawing_color = '#27a4d8'
        view.line_width = 3
        if %i[floor roof].include?(@kind)
          view.draw(::GL_LINE_LOOP, rectangle(@first, @input.position))
        else
          view.draw(::GL_LINES, [@first, @input.position])
        end
      end

      private

      def create_between(first, second)
        model = Sketchup.active_model
        if @kind == :grid
          model.start_operation('Trace Column Grid', true)
          line = model.active_entities.add_cline(first, second)
          line.set_attribute('ForgeBuild.Trace', 'kind', 'grid')
          model.commit_operation
        elsif @kind == :wall
          type, defaults = DEFAULTS[:wall]
          @services.fetch(:wall).create(**defaults.merge(@options).merge(model: model, object_type: type, origin: first, endpoint: second))
        else
          type, defaults = DEFAULTS.fetch(@kind)
          width = (second.x - first.x).abs
          length = (second.y - first.y).abs
          origin = ::Geom::Point3d.new([first.x, second.x].min, [first.y, second.y].min, first.z)
          @services.fetch(@kind).create(**defaults.merge(@options).merge(model: model, object_type: type, origin: origin, width: width, length: length))
        end
      end

      def create_point(point)
        model = Sketchup.active_model
        if @kind == :level
          response = ::UI.inputbox(['Level name', 'Elevation'], ['Level 1', point.z.to_l.to_s], 'Trace Level')
          return unless response
          model.set_attribute('ForgeBuild.Levels', response[0].to_s, response[1].to_l.to_f)
        else
          type, defaults = DEFAULTS[:opening]
          @services.fetch(:wall).create(**defaults.merge(@options).merge(model: model, object_type: type, origin: point))
        end
        Sketchup.status_text = 'Trace created. Click another location or press Esc.'
      end

      def rectangle(first, second)
        [first, ::Geom::Point3d.new(second.x, first.y, first.z), second, ::Geom::Point3d.new(first.x, second.y, first.z)]
      end
    end
  end
end
