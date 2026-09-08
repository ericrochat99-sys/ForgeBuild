# frozen_string_literal: true

module ForgeBuild
  module Database
    # Boundary for the future SQLite adapter and schema migrations.
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
    end
  end
end
