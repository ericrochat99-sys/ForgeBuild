# frozen_string_literal: true

require 'time'

module ForgeBuild
  module Services
    # Builds estimator-facing reports from ForgeBuild metadata without changing geometry.
    class InformationService
      SCHEDULE_TYPES = {
        'Openings' => %w[opening door window louver skylight hatch penetration shaft stair elevator],
        'Structure' => %w[beam girder joist column post pier footing grade_beam foundation_wall],
        'Assemblies' => %w[wall slab floor roof deck]
      }.freeze

      VALIDATION_FIELDS = %i[id builder object_type assembly csi_division cost_code material].freeze

      def initialize(model: nil)
        @model = model
      end

      def report(model: @model || Sketchup.active_model, waste_factors: {}, alternates: {}, allowances: {})
        objects = collect(model)
        {
          generated_at: Time.now.utc.iso8601,
          object_count: objects.length,
          takeoff: takeoff(objects, waste_factors),
          schedules: schedules(objects),
          materials: materials(objects, waste_factors),
          validations: validations(objects),
          clashes: clash_warnings(objects),
          missing_information: missing_information(objects),
          alternates: normalize_named_values(alternates),
          allowances: normalize_named_values(allowances),
          classifications: classifications(objects)
        }
      end

      def collect(model)
        walk(model.entities).filter_map do |entity|
          next unless Models::ParametricObject.forge_build?(entity)

          attributes = Models::ParametricObject.read(entity)
          attributes[:entity] = entity
          attributes[:level] ||= entity.respond_to?(:layer) && entity.layer ? entity.layer.name : 'Untagged'
          attributes[:building] ||= model.respond_to?(:title) && !model.title.to_s.empty? ? model.title : 'Building 1'
          attributes[:area] ||= area_name(entity)
          attributes
        end
      end

      def takeoff(objects, waste_factors = {})
        grouped = objects.group_by { |item| takeoff_key(item) }
        grouped.map do |key, items|
          quantity = items.each_with_object(Hash.new(0.0)) do |item, totals|
            normalize_hash(item[:quantities]).each { |unit, value| totals[unit] += numeric(value) }
          end
          waste = waste_for(items.first, waste_factors)
          {
            assembly: key[0], material: key[1], csi_division: key[2], cost_code: key[3],
            level: key[4], area: key[5], building: key[6], count: items.length,
            waste_factor: waste, quantities: quantity.transform_values { |value| value * (1.0 + waste / 100.0) }
          }
        end.sort_by { |row| [row[:csi_division].to_s, row[:cost_code].to_s, row[:assembly].to_s] }
      end

      def schedules(objects)
        SCHEDULE_TYPES.each_with_object({}) do |(name, keywords), result|
          result[name] = objects.select { |item| keywords.any? { |word| item[:object_type].to_s.include?(word) } }
                                .map { |item| schedule_row(item) }
        end.merge('All Objects' => objects.map { |item| schedule_row(item) })
      end

      def materials(objects, waste_factors = {})
        objects.group_by { |item| [item[:material].to_s, item[:cost_code].to_s] }.map do |(material, cost_code), items|
          quantities = items.each_with_object(Hash.new(0.0)) do |item, totals|
            normalize_hash(item[:quantities]).each { |unit, value| totals[unit] += numeric(value) }
          end
          waste = waste_for(items.first, waste_factors)
          { material: material, cost_code: cost_code, count: items.length, waste_factor: waste,
            quantities: quantities.transform_values { |value| value * (1.0 + waste / 100.0) } }
        end.sort_by { |row| [row[:cost_code], row[:material]] }
      end

      def validations(objects)
        objects.flat_map do |item|
          warnings = []
          warnings << warning(item, 'Fire rating not specified', 'fire') if fire_related?(item) && item[:fire_rating].to_s.empty?
          warnings << warning(item, 'Acoustic rating not specified', 'acoustic') if partition?(item) && parameter(item, :stc).nil?
          warnings << warning(item, 'Thermal value not specified', 'thermal') if envelope?(item) && parameter(item, :r_value).nil?
          if accessibility_related?(item) && parameter(item, :accessible).nil?
            warnings << warning(item, 'Accessibility status not confirmed', 'accessibility')
          end
          warnings
        end
      end

      def missing_information(objects)
        objects.flat_map do |item|
          VALIDATION_FIELDS.filter_map do |field|
            warning(item, "Missing #{field.to_s.tr('_', ' ')}", 'missing_information') if item[field].nil? || item[field].to_s.empty?
          end
        end
      end

      def clash_warnings(objects)
        indexed = objects.select { |item| item[:entity].respond_to?(:bounds) }
        indexed.each_with_index.flat_map do |left, index|
          indexed.drop(index + 1).filter_map do |right|
            next if parent_child?(left, right)
            next unless bounds_overlap?(left[:entity].bounds, right[:entity].bounds)
            next unless coordination_pair?(left, right)

            { severity: 'warning', type: 'possible_clash', left_id: left[:id], right_id: right[:id],
              message: "Possible clash: #{left[:assembly]} / #{right[:assembly]}" }
          end
        end
      end

      def classifications(objects)
        objects.map do |item|
          { id: item[:id], name: item[:assembly], object_type: item[:object_type], builder: item[:builder],
            csi_division: item[:csi_division], cost_code: item[:cost_code], tag: item[:tag],
            ifc_class: ifc_class(item), dwg_layer: item[:tag].to_s.gsub(/[^A-Za-z0-9_-]+/, '-') }
        end
      end

      private

      def walk(entities)
        entities.each_with_object([]) do |entity, result|
          result << entity
          result.concat(walk(entity.entities)) if entity.respond_to?(:entities) && entity.entities
        end
      end

      def takeoff_key(item)
        %i[assembly material csi_division cost_code level area building].map { |field| item[field].to_s }
      end

      def schedule_row(item)
        { id: item[:id], builder: item[:builder], object_type: item[:object_type], assembly: item[:assembly],
          level: item[:level], area: item[:area], building: item[:building], material: item[:material],
          cost_code: item[:cost_code], dimensions: normalize_hash(item[:dimensions]), quantities: normalize_hash(item[:quantities]),
          manufacturer: item[:manufacturer], model_number: item[:model_number], finish: item[:finish], comments: item[:comments] }
      end

      def waste_for(item, factors)
        normalized = normalize_hash(factors)
        numeric(normalized[item[:material].to_s] || normalized[item[:cost_code].to_s] || normalized['default'])
      end

      def normalize_named_values(values)
        normalize_hash(values).map { |name, value| { name: name.to_s, value: numeric(value) } }
      end

      def normalize_hash(value)
        (value || {}).each_with_object({}) { |(key, item), result| result[key.to_s] = item }
      end

      def numeric(value) = Float(value || 0)
      def parameter(item, key) = normalize_hash(item[:parameters])[key.to_s]
      def area_name(entity) = entity.respond_to?(:parent) && entity.parent.respond_to?(:name) ? entity.parent.name.to_s : ''
      def fire_related?(item) = %w[wall door opening penetration].any? { |word| item[:object_type].to_s.include?(word) }
      def partition?(item) = item[:builder].to_s == 'wall'
      def envelope?(item) = %w[wall roof].include?(item[:builder].to_s)
      def accessibility_related?(item) = %w[door opening stair elevator].any? { |word| item[:object_type].to_s.include?(word) }
      def parent_child?(left, right) = left[:parent_id] == right[:id] || right[:parent_id] == left[:id]
      def coordination_pair?(left, right) = left[:builder] != right[:builder] || [left, right].any? { |item| item[:object_type].to_s.match?(/opening|penetration|coordination/) }
      def bounds_overlap?(left, right)
        !(%i[x y z].any? { |axis| left.max.public_send(axis) < right.min.public_send(axis) || right.max.public_send(axis) < left.min.public_send(axis) })
      end
      def warning(item, message, type) = { severity: 'warning', type: type, id: item[:id], assembly: item[:assembly], message: message }
      def ifc_class(item)
        type = item[:object_type].to_s
        return 'IfcDoor' if type.include?('door')
        return 'IfcWindow' if type.include?('window') || type.include?('skylight')
        return 'IfcBeam' if type.match?(/beam|girder|joist/)
        return 'IfcColumn' if type.match?(/column|post|pier/)
        return 'IfcWall' if item[:builder].to_s == 'wall'
        return 'IfcRoof' if item[:builder].to_s == 'roof'
        return 'IfcSlab' if item[:builder].to_s == 'floor'
        'IfcBuildingElementProxy'
      end
    end
  end
end
