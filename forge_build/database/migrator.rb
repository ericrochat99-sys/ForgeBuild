# frozen_string_literal: true

module ForgeBuild
  module Database
    class Migrator
      MIGRATIONS = [
        ['001_core', <<~SQL]
          CREATE TABLE IF NOT EXISTS schema_migrations (version TEXT PRIMARY KEY);
          CREATE TABLE IF NOT EXISTS projects (id TEXT PRIMARY KEY, name TEXT NOT NULL, data TEXT NOT NULL, updated_at TEXT NOT NULL);
          CREATE TABLE IF NOT EXISTS presets (id INTEGER PRIMARY KEY AUTOINCREMENT, builder TEXT NOT NULL, object_type TEXT NOT NULL, name TEXT NOT NULL, parameters TEXT NOT NULL, is_default INTEGER NOT NULL DEFAULT 0, updated_at TEXT NOT NULL, UNIQUE(builder, object_type, name));
        SQL
      ].freeze

      def initialize(connection) = @connection = connection
      def migrate
        @connection.execute('CREATE TABLE IF NOT EXISTS schema_migrations (version TEXT PRIMARY KEY)')
        MIGRATIONS.each do |version, sql|
          next unless @connection.execute('SELECT version FROM schema_migrations WHERE version = ?', [version]).empty?

          @connection.transaction do
            sql.split(';').map(&:strip).reject(&:empty?).each { |statement| @connection.execute(statement) }
            @connection.execute('INSERT INTO schema_migrations(version) VALUES (?)', [version])
          end
        end
      end
    end
  end
end
