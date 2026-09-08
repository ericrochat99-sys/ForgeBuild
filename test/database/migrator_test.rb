# frozen_string_literal: true
require_relative '../test_helper'
require 'database/migrator'
class MigratorTest < Minitest::Test
  class Connection
    attr_reader :statements
    def initialize = @statements = []
    def execute(sql, parameters = [])
      @statements << [sql, parameters]
      sql.start_with?('SELECT version') ? [] : true
    end
    def transaction = yield
  end
  def test_creates_project_and_preset_tables
    connection = Connection.new
    ForgeBuild::Database::Migrator.new(connection).migrate
    sql = connection.statements.map(&:first).join(' ')
    assert_includes sql, 'CREATE TABLE IF NOT EXISTS projects'
    assert_includes sql, 'CREATE TABLE IF NOT EXISTS presets'
  end
end
