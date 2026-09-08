# frozen_string_literal: true

module ForgeBuild
  module Database
    # Small SQLite boundary used by project and preset repositories.
    class Connection
      def initialize(adapter:)
        @adapter = adapter
      end

      # Executes a parameterized statement through the configured adapter.
      def execute(sql, parameters = [])
        @adapter.execute(sql, parameters)
      end

      # Runs a block atomically when supported by the adapter.
      def transaction(&block)
        @adapter.transaction(&block)
      end

      def self.open(path)
        require 'sqlite3'
        database = SQLite3::Database.new(path)
        database.results_as_hash = true
        new(SqliteAdapter.new(database))
      rescue LoadError
        raise LoadError, 'ForgeBuild requires the sqlite3 Ruby library for project storage'
      end

      class SqliteAdapter
        def initialize(database) = @database = database
        def execute(sql, parameters = []) = @database.execute(sql, parameters)
        def transaction
          @database.transaction
          result = yield
          @database.commit
          result
        rescue StandardError
          @database.rollback
          raise
        end
      end
    end
  end
end
