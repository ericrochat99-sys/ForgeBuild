# frozen_string_literal: true

require 'json'
require 'securerandom'
require 'time'

module ForgeBuild
  module Services
    # Registers drawing underlays and preserves calibration/revision history in the model.
    class DrawingService
      DICTIONARY = 'ForgeBuild.Drawings'
      KEY = 'registry'
      SUPPORTED = %w[.pdf .png .jpg .jpeg .tif .tiff .dwg .dxf].freeze

      def import(model:, path:, discipline: 'architectural', sheet: '', revision: '', page: 1)
        extension = File.extname(path).downcase
        raise ArgumentError, "Unsupported drawing format: #{extension}" unless SUPPORTED.include?(extension)

        before = model.entities.to_a.dup
        options = { units: 'inch', merge_coplanar_faces: true, orient_faces: true, preserve_origin: true,
                    page: Integer(page) }
        success = model.import(path, options)
        raise "SketchUp could not import #{File.basename(path)}" unless success
        entity = (model.entities.to_a - before).last || model.selection.first
        raise 'The plan imported, but ForgeBuild could not identify it in the modeling area.' unless entity
        model.start_operation('Register ForgeBuild Drawing', true)
        operation_open = true
        drawing = register(model: model, entity: entity, path: path, discipline: discipline,
                           sheet: sheet, revision: revision, page: page)
        model.commit_operation
        operation_open = false
        drawing
      rescue StandardError
        model.abort_operation if operation_open && model.respond_to?(:abort_operation)
        raise
      end

      def focus(model:, drawing:)
        entity = find_entity(model, drawing[:entity_id])
        raise 'The imported plan is no longer available in the modeling area.' unless entity

        model.selection.clear
        model.selection.add(entity)
        view = model.active_view
        view.zoom(entity) if view.respond_to?(:zoom)
        { drawing: drawing, entity: entity }
      end

      def register(model:, entity:, path:, discipline:, sheet: '', revision: '', page: 1)
        drawing = {
          id: SecureRandom.uuid, path: path.to_s, filename: File.basename(path.to_s), discipline: discipline.to_s,
          sheet: sheet.to_s, revision: revision.to_s, page: Integer(page), imported_at: Time.now.utc.iso8601,
          scale: 1.0, rotation: 0.0, origin: [0.0, 0.0, 0.0], visible: true, entity_id: persistent_id(entity)
        }
        save(model, registry(model) + [drawing])
        stamp(entity, drawing) if entity
        drawing
      end

      def calibrate(model:, id:, measured_length:, actual_length:)
        measured = Float(measured_length)
        actual = Float(actual_length)
        raise ArgumentError, 'Calibration lengths must be greater than zero' unless measured.positive? && actual.positive?
        update(model, id, scale: actual / measured)
      end

      def align(model:, id:, rotation: nil, origin: nil)
        changes = {}
        changes[:rotation] = Float(rotation) unless rotation.nil?
        changes[:origin] = Array(origin).map { |value| Float(value) } if origin
        update(model, id, changes)
      end

      def add_revision(model:, id:, revision:, path: nil, notes: '')
        current = find(model, id)
        history = Array(current[:revisions])
        history << { revision: revision.to_s, path: (path || current[:path]).to_s,
                     notes: notes.to_s, recorded_at: Time.now.utc.iso8601 }
        update(model, id, revision: revision.to_s, path: (path || current[:path]).to_s, revisions: history)
      end

      def compare_revisions(model:, id:, older:, newer:)
        drawing = find(model, id)
        revisions = Array(drawing[:revisions])
        left = revisions.find { |item| item[:revision].to_s == older.to_s }
        right = revisions.find { |item| item[:revision].to_s == newer.to_s }
        raise KeyError, 'Both drawing revisions must be registered before comparison' unless left && right
        { drawing_id: id, from: left, to: right, changed: left[:path] != right[:path] || left[:notes] != right[:notes] }
      end

      def registry(model)
        raw = model.get_attribute(DICTIONARY, KEY, '[]')
        JSON.parse(raw, symbolize_names: true)
      rescue JSON::ParserError
        []
      end

      def find(model, id)
        registry(model).find { |drawing| drawing[:id] == id } || raise(KeyError, "Unknown drawing: #{id}")
      end

      def update(model, id, changes)
        drawings = registry(model)
        index = drawings.index { |drawing| drawing[:id] == id }
        raise KeyError, "Unknown drawing: #{id}" unless index
        drawings[index] = drawings[index].merge(changes)
        save(model, drawings)
        drawings[index]
      end

      private

      def save(model, drawings)
        model.set_attribute(DICTIONARY, KEY, JSON.generate(drawings))
      end
      def stamp(entity, drawing)
        drawing.each { |key, value| entity.set_attribute('ForgeBuild.Drawing', key.to_s, value.is_a?(Array) || value.is_a?(Hash) ? JSON.generate(value) : value) }
        entity.name = "ForgeBuild Drawing #{drawing[:sheet]}" if entity.respond_to?(:name=)
      end
      def persistent_id(entity) = entity.respond_to?(:persistent_id) ? entity.persistent_id : nil
      def find_entity(model, id)
        return nil unless id
        return model.find_entity_by_persistent_id(id) if model.respond_to?(:find_entity_by_persistent_id)
        model.entities.find { |entity| entity.respond_to?(:persistent_id) && entity.persistent_id == id }
      end
    end
  end
end
