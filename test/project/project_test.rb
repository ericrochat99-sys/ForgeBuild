# frozen_string_literal: true

require_relative '../test_helper'
require 'project/project'

class ProjectTest < Minitest::Test
  def test_builds_valid_project
    project = ForgeBuild::Project::Project.new(name: 'School', stories: 2)
    assert_equal 'School', project.name
    assert_equal 2, project.stories
  end

  def test_rejects_missing_name
    assert_raises(ArgumentError) { ForgeBuild::Project::Project.new(name: ' ') }
  end

  def test_rejects_invalid_story_count
    assert_raises(ArgumentError) { ForgeBuild::Project::Project.new(name: 'School', stories: 0) }
  end
end
