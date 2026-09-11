# frozen_string_literal: true

module ForgeBuild
  module Tools
    # Parametric face-drag tool for ForgeBuild groups. Unlike SketchUp's native
    # Push/Pull, this updates stored dimensions and regenerates the assembly.
    class AssemblyPushPullTool
      AXES = { x: X_AXIS, y: Y_AXIS, z: Z_AXIS }.freeze
      PARAMETERS = {
        x: %w[length width],
        y: %w[thickness depth],
        z: %w[height]
      }.freeze

      def initialize(service:, entity:)
        @service = service
        @entity = entity
        @input = ::Sketchup::InputPoint.new
      end

      def activate
        validate_entity!
        reset_drag
        Sketchup.status_text = 'Push/Pull Assembly: hover a face, then click and drag. Click again or type a dimension.'
      rescue StandardError => error
        ::UI.messagebox(error.message)
        Sketchup.active_model.select_tool(nil)
      end

      def onMouseMove(_flags, x, y, view)
        if @dragging
          update_drag(view, x, y)
        else
          pick_face(view, x, y)
        end
        view.invalidate
      end

      def onLButtonDown(_flags, x, y, view)
        if @dragging
          commit_resize(view)
        elsif pick_face(view, x, y)
          begin_drag
        end
      rescue StandardError => error
        ::UI.messagebox("ForgeBuild could not resize the assembly: #{error.message}")
        reset_drag
        view.invalidate
      end

      def onUserText(text, view)
        return unless @dragging

        @new_value = text.to_l.to_f
        raise ArgumentError, 'The new assembly dimension must be greater than zero.' unless @new_value.positive?

        @delta = (@new_value - @start_value) / @face_sign
        commit_resize(view)
      rescue StandardError => error
        ::UI.messagebox(error.message)
      end

      def onCancel(_reason, view)
        reset_drag
        view.invalidate
        Sketchup.status_text = 'Push/Pull Assembly canceled.'
      end

      def draw(view)
        draw_hover_face(view)
        return unless @dragging && @axis_point

        view.drawing_color = '#d87832'
        view.line_width = 3
        view.draw(::GL_LINES, [@start_point, @axis_point])
        screen = view.screen_coords(@axis_point)
        view.draw_text([screen.x + 14, screen.y - 24],
                       "#{label(@parameter)}: #{@new_value.to_l}",
                       color: '#ffffff', background: '#2d3036', size: 12, bold: true)
      end

      def getExtents
        bounds = ::Geom::BoundingBox.new
        bounds.add(@entity.bounds) if @entity&.valid?
        bounds.add(@axis_point) if @axis_point
        bounds
      end

      private

      def validate_entity!
        raise ArgumentError, 'Select a ForgeBuild assembly before using Push/Pull Assembly.' unless @entity&.valid?
        raise ArgumentError, 'The selected object is not a ForgeBuild assembly.' unless Models::ParametricObject.forge_build?(@entity)
      end

      def pick_face(view, x, y)
        helper = view.pick_helper
        helper.do_pick(x, y)
        path = (0...helper.count).map { |index| helper.path_at(index) }
                                  .find { |candidate| candidate&.include?(@entity) && candidate.any? { |item| item.is_a?(::Sketchup::Face) } }
        @hover_face = path&.reverse&.find { |item| item.is_a?(::Sketchup::Face) }
        @hover_path = path
        @input.pick(view, x, y)
        view.tooltip = @hover_face ? 'Click and drag to resize this ForgeBuild assembly' : 'Choose an assembly face'
        !@hover_face.nil?
      end

      def begin_drag
        normal = @hover_face.normal
        @axis_name = dominant_axis(normal)
        @parameter = parameter_for(@axis_name)
        raise ArgumentError, 'This face does not map to an editable ForgeBuild dimension.' unless @parameter

        component = { x: normal.x, y: normal.y, z: normal.z }.fetch(@axis_name)
        @face_sign = component.negative? ? -1.0 : 1.0
        @axis_world = AXES.fetch(@axis_name).transform(@entity.transformation).normalize
        @start_point = @input.position
        @axis_point = @start_point
        @start_value = parameter_value(@parameter)
        @new_value = @start_value
        @delta = 0.0
        @dragging = true
        Sketchup.status_text = "Drag to change #{label(@parameter)}, click to finish, or type the new dimension."
      end

      def update_drag(view, x, y)
        ray = view.pickray(x, y)
        points = ::Geom.closest_points(ray, [@start_point, @axis_world])
        return unless points && points[1]

        @axis_point = points[1]
        @delta = (@axis_point - @start_point).dot(@axis_world)
        candidate = @start_value + (@delta * @face_sign)
        @new_value = [candidate, 0.01].max
        Sketchup.status_text = "#{label(@parameter)}: #{@new_value.to_l} — click to apply or type a dimension."
      end

      def commit_resize(view)
        shift = nil
        if @face_sign.negative?
          vector = @axis_world.clone
          vector.length = @delta.abs
          vector.reverse! if @delta.negative?
          shift = vector.to_a
        end
        @service.resize(@entity, parameter: @parameter, value: @new_value, shift_vector: shift)
        Sketchup.status_text = "#{label(@parameter)} updated to #{@new_value.to_l}. Choose another face or press Esc."
        reset_drag
        view.invalidate
      end

      def dominant_axis(normal)
        { x: normal.x.abs, y: normal.y.abs, z: normal.z.abs }.max_by { |_axis, value| value }.first
      end

      def parameter_for(axis)
        parameters = Models::ParametricObject.read(@entity).fetch(:parameters, {})
        PARAMETERS.fetch(axis).find { |name| parameters.key?(name) || parameters.key?(name.to_sym) }
      end

      def parameter_value(name)
        parameters = Models::ParametricObject.read(@entity).fetch(:parameters, {})
        Float(parameters[name] || parameters[name.to_sym])
      end

      def draw_hover_face(view)
        return unless @hover_face && @entity&.valid?

        points = @hover_face.vertices.map { |vertex| vertex.position.transform(@entity.transformation) }
        fill = ::Sketchup::Color.new('#d87832')
        fill.alpha = @dragging ? 75 : 40
        view.drawing_color = fill
        view.draw(::GL_POLYGON, points)
        view.drawing_color = '#f3a15b'
        view.line_width = 2
        view.draw(::GL_LINE_LOOP, points)
      end

      def reset_drag
        @dragging = false
        @hover_face = nil
        @hover_path = nil
        @axis_point = nil
        @parameter = nil
      end

      def label(parameter) = parameter.to_s.split('_').map(&:capitalize).join(' ')
    end
  end
end
