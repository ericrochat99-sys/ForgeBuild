# frozen_string_literal: true

require_relative '../test_helper'

unless defined?(::Geom::Point3d)
  module Geom
    Point3d = Struct.new(:x, :y, :z)
  end
end

require_relative '../../forge_build/tools/inference_support'

module ForgeBuild
  module Tools
    class InferenceSupportTest < Minitest::Test
      Subject = Class.new { include InferenceSupport }

      def setup
        @subject = Subject.new
        @anchor = Geom::Point3d.new(10, 20, 30)
        @point = Geom::Point3d.new(50, 60, 70)
      end

      def test_axis_constraints_match_sketchup_arrow_keys
        assert_equal [50, 20, 30], coordinates(@subject.constrained_position(@point, @anchor, :red))
        assert_equal [10, 60, 30], coordinates(@subject.constrained_position(@point, @anchor, :green))
        assert_equal [10, 20, 70], coordinates(@subject.constrained_position(@point, @anchor, :blue))
      end

      def test_drawing_plane_constraint_preserves_underlay_elevation
        assert_equal [50, 60, 30], coordinates(@subject.constrained_position(@point, @anchor, :drawing_plane))
      end

      def test_unconstrained_point_is_unchanged
        assert_same @point, @subject.constrained_position(@point, @anchor, nil)
      end

      private

      def coordinates(point) = [point.x, point.y, point.z]
    end
  end
end
