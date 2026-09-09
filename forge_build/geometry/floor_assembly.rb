# frozen_string_literal: true

require_relative 'rectangular_prism'

module ForgeBuild
  module Geometry
    module FloorAssembly
      module_function

      def area(entities:, width:, length:, thickness:, elevation: 0, slope: 0, edge_width: 0, edge_depth: 0,
               flute_spacing: 0, **_options)
        origin = ::Geom::Point3d.new(0, 0, elevation)
        if slope.to_f.zero?
          RectangularPrism.create(entities: entities, origin: origin, width: width, length: length, height: thickness)
        else
          wedge(entities, origin, width, length, thickness, width * slope.to_f / 100.0)
        end
        turndown(entities, width, length, edge_width.to_f, edge_depth.to_f, elevation) if edge_width.to_f.positive? && edge_depth.to_f.positive?
        ribs(entities, width, length, thickness, elevation, flute_spacing.to_f) if flute_spacing.to_f.positive?
      end

      def linear(entities:, length:, width:, height:, system: '', **_options)
        if system.to_s == 'steel_joist'
          chord = [height * 0.08, 0.5].max
          RectangularPrism.create(entities: entities, origin: ::Geom::Point3d.new(0, 0, 0), width: length, length: width, height: chord)
          RectangularPrism.create(entities: entities, origin: ::Geom::Point3d.new(0, 0, height - chord), width: length, length: width, height: chord)
          panels = [(length / 24.0).ceil, 1].max
          step = length / panels
          panels.times do |index|
            a = ::Geom::Point3d.new(index * step, width / 2.0, chord)
            b = ::Geom::Point3d.new((index + 0.5) * step, width / 2.0, height - chord)
            c = ::Geom::Point3d.new((index + 1) * step, width / 2.0, chord)
            entities.add_line(a, b)
            entities.add_line(b, c)
          end
        else
          RectangularPrism.create(entities: entities, origin: ::Geom::Point3d.new(0, 0, 0), width: length, length: width, height: [height, 0.01].max)
        end
      end

      def point(entities:, width:, length:, height:, system: '', **_options)
        if system.to_s == 'circular_opening'
          center = ::Geom::Point3d.new(width / 2.0, length / 2.0, 0)
          edges = entities.add_circle(center, Z_AXIS, width / 2.0, 24)
          face = entities.add_face(edges)
          face.pushpull([height, 0.01].max)
        else
          RectangularPrism.create(entities: entities, origin: ::Geom::Point3d.new(0, 0, 0), width: width, length: length, height: [height, 0.01].max)
        end
      end

      def wedge(entities, origin, width, length, thickness, rise)
        x, y, z = origin.x, origin.y, origin.z
        bottom = [[x, y, z], [x + width, y, z], [x + width, y + length, z], [x, y + length, z]].map { |p| ::Geom::Point3d.new(p) }
        top = [[x, y, z + thickness], [x + width, y, z + thickness + rise],
               [x + width, y + length, z + thickness + rise], [x, y + length, z + thickness]].map { |p| ::Geom::Point3d.new(p) }
        entities.add_face(bottom.reverse)
        entities.add_face(top)
        4.times { |index| entities.add_face(bottom[index], bottom[(index + 1) % 4], top[(index + 1) % 4], top[index]) }
      end

      def turndown(entities, width, length, edge_width, edge_depth, elevation)
        z = elevation - edge_depth
        RectangularPrism.create(entities: entities, origin: ::Geom::Point3d.new(0, 0, z), width: width, length: edge_width, height: edge_depth)
        RectangularPrism.create(entities: entities, origin: ::Geom::Point3d.new(0, length - edge_width, z), width: width, length: edge_width, height: edge_depth)
        RectangularPrism.create(entities: entities, origin: ::Geom::Point3d.new(0, edge_width, z), width: edge_width, length: [length - 2 * edge_width, 0.01].max, height: edge_depth)
        RectangularPrism.create(entities: entities, origin: ::Geom::Point3d.new(width - edge_width, edge_width, z), width: edge_width, length: [length - 2 * edge_width, 0.01].max, height: edge_depth)
      end

      def ribs(entities, width, length, thickness, elevation, spacing)
        x = 0.0
        while x <= width
          RectangularPrism.create(entities: entities, origin: ::Geom::Point3d.new(x, 0, elevation + thickness),
                                  width: [spacing * 0.12, 0.1].max, length: length, height: [thickness * 0.12, 0.05].max)
          x += spacing
        end
      end
    end
  end
end
