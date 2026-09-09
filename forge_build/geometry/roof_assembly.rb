# frozen_string_literal: true

require_relative 'rectangular_prism'
require_relative 'floor_assembly'

module ForgeBuild
  module Geometry
    module RoofAssembly
      module_function
      def area(entities:, width:, length:, thickness:, pitch: 0, elevation: 0, system: '', seam_spacing: 0, **_options)
        overhang = _options.fetch(:overhang, 0).to_f
        width += overhang * 2
        length += overhang * 2
        elevation_origin = elevation
        case system.to_s
        when 'gable_roof' then gable(entities, width, length, thickness, pitch, elevation_origin)
        when 'hip_roof' then hip(entities, width, length, thickness, pitch, elevation_origin)
        else
          FloorAssembly.area(entities: entities, width: width, length: length, thickness: thickness,
                             elevation: elevation_origin, slope: pitch.to_f * 100.0 / 12.0)
        end
        seams(entities, width, length, thickness, elevation_origin, seam_spacing) if seam_spacing.to_f.positive?
      end

      def linear(entities:, length:, width:, height:, system: '', **options)
        FloorAssembly.linear(entities: entities, length: length, width: width, height: height,
                             system: system == 'steel_joist' ? 'steel_joist' : system, **options)
      end

      def point(entities:, width:, depth:, height:, system: '', **_options)
        if %w[roof_drain overflow_drain roof_penetration].include?(system.to_s)
          edges = entities.add_circle(::Geom::Point3d.new(width / 2.0, depth / 2.0, 0), Z_AXIS, width / 2.0, 24)
          entities.add_face(edges).pushpull(height)
        else
          RectangularPrism.create(entities: entities, origin: ::Geom::Point3d.new(0, 0, 0), width: width, length: depth, height: height)
        end
      end

      def gable(entities, width, length, thickness, pitch, elevation)
        rise = width / 2.0 * pitch.to_f / 12.0
        bottom = [[0, 0, elevation], [width, 0, elevation], [width, length, elevation], [0, length, elevation]].map { |p| ::Geom::Point3d.new(p) }
        top = [[0, 0, elevation + thickness], [width / 2.0, 0, elevation + thickness + rise], [width, 0, elevation + thickness],
               [width, length, elevation + thickness], [width / 2.0, length, elevation + thickness + rise], [0, length, elevation + thickness]].map { |p| ::Geom::Point3d.new(p) }
        entities.add_face(bottom.reverse)
        entities.add_face(top[0], top[1], top[4], top[5])
        entities.add_face(top[1], top[2], top[3], top[4])
        entities.add_face(bottom[0], bottom[1], top[2], top[1], top[0])
        entities.add_face(bottom[1], bottom[2], top[3], top[2])
        entities.add_face(bottom[2], bottom[3], top[5], top[4], top[3])
        entities.add_face(bottom[3], bottom[0], top[0], top[5])
      end

      def hip(entities, width, length, thickness, pitch, elevation)
        rise = [width, length].min / 2.0 * pitch.to_f / 12.0
        bottom = [[0, 0, elevation], [width, 0, elevation], [width, length, elevation], [0, length, elevation]].map { |p| ::Geom::Point3d.new(p) }
        peak = ::Geom::Point3d.new(width / 2.0, length / 2.0, elevation + thickness + rise)
        entities.add_face(bottom.reverse)
        4.times do |i|
          a, b = bottom[i], bottom[(i + 1) % 4]
          entities.add_face(a.offset(Z_AXIS, thickness), b.offset(Z_AXIS, thickness), peak)
          entities.add_face(a, b, b.offset(Z_AXIS, thickness), a.offset(Z_AXIS, thickness))
        end
      end

      def seams(entities, width, length, thickness, elevation, spacing)
        x = 0.0
        while x <= width
          entities.add_line([x, 0, elevation + thickness], [x, length, elevation + thickness])
          x += spacing
        end
      end
    end
  end
end
