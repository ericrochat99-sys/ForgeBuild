# frozen_string_literal: true

require_relative 'rectangular_prism'

module ForgeBuild
  module Geometry
    module WallAssembly
      module_function
      def line(entities:, length:, thickness:, height:, end_height: nil, stud_spacing: 0, system: '', **_options)
        finish = end_height.to_f.positive? ? end_height.to_f : height
        if (finish - height).abs > 0.001
          wedge(entities, length, thickness, height, finish)
        else
          RectangularPrism.create(entities: entities, origin: ::Geom::Point3d.new(0, 0, 0), width: length, length: thickness, height: height)
        end
        studs(entities, length, thickness, height, stud_spacing.to_f) if system.to_s.include?('stud') && stud_spacing.to_f.positive?
      end

      def point(entities:, width:, depth:, height:, system: '', **_options)
        RectangularPrism.create(entities: entities, origin: ::Geom::Point3d.new(0, 0, 0), width: width, length: depth, height: height)
      end

      def wedge(entities, length, thickness, start_height, end_height)
        bottom = [[0, 0, 0], [length, 0, 0], [length, thickness, 0], [0, thickness, 0]].map { |p| ::Geom::Point3d.new(p) }
        top = [[0, 0, start_height], [length, 0, end_height], [length, thickness, end_height], [0, thickness, start_height]].map { |p| ::Geom::Point3d.new(p) }
        entities.add_face(bottom.reverse)
        entities.add_face(top)
        4.times { |i| entities.add_face(bottom[i], bottom[(i + 1) % 4], top[(i + 1) % 4], top[i]) }
      end

      def studs(entities, length, thickness, height, spacing)
        x = 0.0
        while x <= length
          RectangularPrism.create(entities: entities, origin: ::Geom::Point3d.new(x, thickness * 0.15, 0),
                                  width: [thickness * 0.2, 0.5].max, length: thickness * 0.7, height: height)
          x += spacing
        end
      end
    end
  end
end
