# frozen_string_literal: true

require 'json'
require 'time'

module ForgeBuild
  module Services
    class PresetService
      def initialize(connection:, settings:)
        @connection = connection
        @settings = settings
      end
      def available? = !@connection.nil?

      def list(builder:, object_type:)
        return [] unless available?
        @connection.execute('SELECT name, parameters, is_default FROM presets WHERE builder = ? AND object_type = ? ORDER BY is_default DESC, name', [builder.to_s, object_type.to_s]).map do |row|
          { name: value(row, 'name'), parameters: JSON.parse(value(row, 'parameters')), default: value(row, 'is_default').to_i == 1 }
        end
      end

      def save(builder:, object_type:, name:, parameters:, default: false)
        raise ArgumentError, 'Preset name is required' if name.to_s.strip.empty?
        unless available?
          @settings.set("preset.#{builder}.#{object_type}.#{name}", JSON.generate(parameters))
          return { name: name, parameters: parameters, default: default }
        end
        @connection.transaction do
          @connection.execute('UPDATE presets SET is_default = 0 WHERE builder = ? AND object_type = ?', [builder.to_s, object_type.to_s]) if default
          @connection.execute('INSERT INTO presets(builder, object_type, name, parameters, is_default, updated_at) VALUES (?, ?, ?, ?, ?, ?) ON CONFLICT(builder, object_type, name) DO UPDATE SET parameters = excluded.parameters, is_default = excluded.is_default, updated_at = excluded.updated_at', [builder.to_s, object_type.to_s, name.to_s.strip, JSON.generate(parameters), default ? 1 : 0, Time.now.utc.iso8601])
        end
        { name: name, parameters: parameters, default: default }
      end

      private
      def value(row, key) = row.respond_to?(:key?) && row.key?(key) ? row[key] : row[key.to_sym]
    end
  end
end
