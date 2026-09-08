# frozen_string_literal: true

require 'json'
require 'time'

module ForgeBuild
  module Services
    class ProjectStore
      def initialize(connection:) = @connection = connection
      def save(project)
        raise LoadError, 'SQLite storage is unavailable' unless @connection
        data = project.respond_to?(:to_h) ? project.to_h : project
        id = data[:id] || data['id']
        name = data[:name] || data['name']
        @connection.execute('INSERT INTO projects(id, name, data, updated_at) VALUES (?, ?, ?, ?) ON CONFLICT(id) DO UPDATE SET name = excluded.name, data = excluded.data, updated_at = excluded.updated_at', [id, name, JSON.generate(data), Time.now.utc.iso8601])
        data
      end
      def find(id)
        row = @connection.execute('SELECT data FROM projects WHERE id = ?', [id.to_s]).first
        row && JSON.parse(row['data'] || row[:data])
      end
    end
  end
end
