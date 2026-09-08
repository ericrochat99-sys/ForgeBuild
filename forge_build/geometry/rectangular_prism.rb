# frozen_string_literal: true

module ForgeBuild
  module Geometry
    module RectangularPrism
      module_function

      def create(entities:, origin:, width:, length:, height:)
        raise ArgumentError, 'Dimensions must be greater than zero' unless [width, length, height].all?(&:positive?)

        points = [origin,
                  origin.offset(::Geom::Vector3d.new(width, 0, 0)),
                  origin.offset(::Geom::Vector3d.new(width, length, 0)),
                  origin.offset(::Geom::Vector3d.new(0, length, 0))]
        face = entities.add_face(points)
        raise 'Unable to create rectangular face' unless face

        face.reverse! if face.normal.z.negative?
        face.pushpull(height)
        face
      end
    end
  end
end
