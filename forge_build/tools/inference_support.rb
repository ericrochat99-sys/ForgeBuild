# frozen_string_literal: true

module ForgeBuild
  module Tools
    # Shared SketchUp-style snapping and keyboard constraints for every placement tool.
    module InferenceSupport
      SHIFT_KEY = 16
      ESC_KEY = 27
      LEFT_KEY = 37
      UP_KEY = 38
      RIGHT_KEY = 39
      DOWN_KEY = 40

      def pick_with_inference(view, x, y)
        if @anchor_input && @anchor_input.valid?
          @input.pick(view, x, y, @anchor_input)
        else
          @input.pick(view, x, y)
        end
        @inference_position = constrained_position(@input.position, inference_anchor, @axis_constraint) if @input.valid?
        view.tooltip = inference_tooltip if @input.valid?
        @input.valid?
      end

      def inference_position
        @inference_position || @input.position
      end

      def controlled_position(anchor = inference_anchor)
        point = inference_position
        return point unless point && anchor

        point = snap_point_to_angle(anchor, point) if truthy_option(:snap_to_angle, true)
        point = snap_point_to_distance(anchor, point) if truthy_option(:snap_to_distance, false)
        point
      end

      def remember_inference_anchor
        @anchor_input = ::Sketchup::InputPoint.new(@input)
        @inference_position = @input.position
      rescue ArgumentError
        @anchor_input = nil
      end

      def clear_inference
        @anchor_input = nil
        @axis_constraint = nil
        @inference_position = nil
      end

      def onKeyDown(key, _repeat, _flags, view)
        if key == ESC_KEY
          clear_inference
          Sketchup.active_model.select_tool(nil)
          return
        elsif key == SHIFT_KEY && @input.valid?
          view.lock_inference(@input)
          @inference_locked = true
        elsif [LEFT_KEY, RIGHT_KEY, UP_KEY, DOWN_KEY].include?(key)
          @axis_constraint = { RIGHT_KEY => :red, LEFT_KEY => :green, UP_KEY => :blue, DOWN_KEY => :drawing_plane }[key]
          view.invalidate
        end
      end

      def onKeyUp(key, _repeat, _flags, view)
        return unless key == SHIFT_KEY && @inference_locked
        view.lock_inference
        @inference_locked = false
      end

      def draw_inference_point(view)
        @input.draw(view) if @input.valid? && @input.respond_to?(:draw)
      end

      # Draws a high-contrast, screen-scaled target before the first click so the
      # user can see the exact inferred start point without obscuring the plan.
      def draw_placement_cursor(view, point = inference_position, color = '#d95f32')
        return unless point

        radius = view.pixels_to_model(9, point)
        x_axis = ::Geom::Vector3d.new(radius, 0, 0)
        y_axis = ::Geom::Vector3d.new(0, radius, 0)
        view.line_stipple = ''
        view.line_width = 3
        view.drawing_color = color
        view.draw(::GL_LINES, [point.offset(x_axis.reverse), point.offset(x_axis),
                               point.offset(y_axis.reverse), point.offset(y_axis)])
        view.draw_points([point], 11, 2, color)
      end

      def draw_dimension_label(view, origin, endpoint, prefix = 'Length')
        return unless origin && endpoint
        distance = origin.distance(endpoint)
        return unless distance.positive?

        midpoint = ::Geom.linear_combination(0.5, origin, 0.5, endpoint)
        label = "#{prefix}: #{format_model_length(distance)}"
        view.draw_text(view.screen_coords(midpoint), label,
                       size: 14, bold: true, color: '#ffffff', align: TextAlignLeft)
      rescue StandardError
        # draw_text signatures vary by SketchUp version. Dimension feedback is
        # supplemental, so never let it break placement.
      end

      def format_model_length(value)
        return value.to_l.to_s if value.respond_to?(:to_l)

        value.to_s
      rescue StandardError
        format('%.2f in.', value.to_f)
      end

      # Returns the plan-view outline of a linear assembly centered on its
      # placement baseline. Thickness is expressed in SketchUp model inches.
      def linear_footprint(origin, endpoint, thickness, alignment = :center)
        run = endpoint - origin
        return [] unless run.length.positive?

        normal = ::Geom::Vector3d.new(-run.y, run.x, 0)
        return [] unless normal.length.positive?

        normal.length = thickness.to_f
        left, right = case alignment.to_sym
                      when :left then [normal, ::Geom::Vector3d.new(0, 0, 0)]
                      when :right then [::Geom::Vector3d.new(0, 0, 0), normal.reverse]
                      else
                        half = normal.clone
                        half.length = thickness.to_f / 2.0
                        [half, half.reverse]
                      end
        [origin.offset(left), endpoint.offset(left),
         endpoint.offset(right), origin.offset(right)]
      end

      # Converts the guide-line endpoints into the baseline expected by the
      # geometry service, whose local wall depth extends in positive Y.
      def aligned_run(origin, endpoint, thickness, alignment = :center)
        run = endpoint - origin
        return [origin, endpoint] unless run.length.positive?

        normal = ::Geom::Vector3d.new(-run.y, run.x, 0)
        return [origin, endpoint] unless normal.length.positive?

        distance = case alignment.to_sym
                   when :left then 0.0
                   when :right then -thickness.to_f
                   else -thickness.to_f / 2.0
                   end
        normal.length = distance.abs
        normal.reverse! if distance.negative?
        [origin.offset(normal), endpoint.offset(normal)]
      end

      def draw_linear_assembly_preview(view, origin, endpoint, thickness, color = '#a85d38', alignment = :center)
        points = linear_footprint(origin, endpoint, thickness, alignment)
        return if points.empty?

        fill = ::Sketchup::Color.new(color)
        fill.alpha = 55
        view.drawing_color = fill
        view.draw(::GL_POLYGON, points)
        view.drawing_color = color
        view.line_stipple = ''
        view.line_width = 3
        view.draw(::GL_LINE_LOOP, points)
        view.draw(::GL_LINES, [origin, endpoint])
        draw_dimension_label(view, origin, endpoint)
      end

      def constrained_position(point, anchor, axis)
        return point unless anchor && axis
        x, y, z = point.x, point.y, point.z
        case axis
        when :red then ::Geom::Point3d.new(x, anchor.y, anchor.z)
        when :green then ::Geom::Point3d.new(anchor.x, y, anchor.z)
        when :blue then ::Geom::Point3d.new(anchor.x, anchor.y, z)
        when :drawing_plane then ::Geom::Point3d.new(x, y, anchor.z)
        else point
        end
      end

      private

      def option_value(name, default = nil)
        return default unless defined?(@options) && @options

        @options.fetch(name, @options.fetch(name.to_s, default))
      end

      def truthy_option(name, default = false)
        value = option_value(name, default)
        value == true || value.to_s.downcase == 'true' || value.to_s == '1'
      end

      def numeric_option(name, default)
        value = option_value(name, default)
        return value.to_l if value.respond_to?(:to_l) && value.to_s =~ /['"a-z]/i
        Float(value)
      rescue StandardError
        default
      end

      def snap_point_to_angle(anchor, point)
        run = point - anchor
        return point unless run.length.positive?

        increment = numeric_option(:snap_angle, 45.0).to_f
        return point unless increment.positive?

        angle = Math.atan2(run.y, run.x)
        snapped = (angle / increment.degrees).round * increment.degrees
        planar_length = Math.sqrt((run.x * run.x) + (run.y * run.y))
        ::Geom::Point3d.new(anchor.x + (Math.cos(snapped) * planar_length),
                            anchor.y + (Math.sin(snapped) * planar_length),
                            point.z)
      end

      def snap_point_to_distance(anchor, point)
        run = point - anchor
        distance = run.length
        increment = numeric_option(:snap_distance, 12.0).to_f
        return point unless distance.positive? && increment.positive?

        snapped = (distance / increment).round * increment
        snapped = increment if snapped.zero?
        vector = run
        vector.length = snapped
        anchor.offset(vector)
      rescue StandardError
        point
      end

      def inference_anchor
        return @origin if defined?(@origin) && @origin
        return @first if defined?(@first) && @first
        nil
      end

      def inference_tooltip
        label = @input.tooltip.to_s
        constraint = { red: 'Red axis', green: 'Green axis', blue: 'Blue axis', drawing_plane: 'Drawing plane' }[@axis_constraint]
        snap = []
        snap << "#{numeric_option(:snap_angle, 45).to_i}°" if truthy_option(:snap_to_angle, true)
        snap << "#{numeric_option(:snap_distance, 12).to_i} in." if truthy_option(:snap_to_distance, false)
        suffix = (constraint ? [constraint] : []) + snap
        suffix.empty? ? label : "#{label} · #{suffix.join(' · ')}"
      end
    end
  end
end
