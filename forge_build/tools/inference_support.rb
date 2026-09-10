# frozen_string_literal: true

module ForgeBuild
  module Tools
    # Shared SketchUp-style snapping and keyboard constraints for every placement tool.
    module InferenceSupport
      SHIFT_KEY = 16
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
        if key == SHIFT_KEY && @input.valid?
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

      def inference_anchor
        return @origin if defined?(@origin) && @origin
        return @first if defined?(@first) && @first
        nil
      end

      def inference_tooltip
        label = @input.tooltip.to_s
        constraint = { red: 'Red axis', green: 'Green axis', blue: 'Blue axis', drawing_plane: 'Drawing plane' }[@axis_constraint]
        constraint ? "#{label} · #{constraint}" : label
      end
    end
  end
end
