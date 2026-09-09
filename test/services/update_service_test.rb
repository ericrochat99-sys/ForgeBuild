# frozen_string_literal: true

require_relative '../test_helper'
require 'json'
require 'services/update_service'

class UpdateServiceTest < Minitest::Test
  Response = Struct.new(:status_code, :body)

  def test_detects_newer_release_and_rbz
    service = ForgeBuild::Services::UpdateService.new(current_version: '0.1.0')
    body = JSON.generate(tag_name: 'v0.1.1', html_url: 'https://github.com/release',
                         assets: [{ name: 'ForgeBuild.rbz', browser_download_url: 'https://github.com/file.rbz' }])
    result = service.send(:parse_response, Response.new(200, body))
    assert_equal 'available', result[:status]
    assert_equal 'https://github.com/file.rbz', result[:download_url]
  end

  def test_reports_current_release
    service = ForgeBuild::Services::UpdateService.new(current_version: '0.1.1')
    body = JSON.generate(tag_name: 'v0.1.1', assets: [])
    assert_equal 'current', service.send(:parse_response, Response.new(200, body))[:status]
  end

  def test_accepts_zip_archive_signature
    service = ForgeBuild::Services::UpdateService.new(current_version: '0.2.0')
    assert service.send(:valid_archive?, "PK\x03\x04".b + ('data' * 30))
    refute service.send(:valid_archive?, '<html>not an archive</html>')
  end

  def test_allows_hot_reload_for_patch_updates_only
    service = ForgeBuild::Services::UpdateService.new(current_version: '1.0.1')
    assert service.send(:hot_reload_eligible?, '1.0.2')
    refute service.send(:hot_reload_eligible?, '1.1.0')
    refute service.send(:hot_reload_eligible?, '2.0.0')
  end

  def test_reload_file_list_excludes_updater_itself
    service = ForgeBuild::Services::UpdateService.new(current_version: '1.0.1')
    files = service.send(:reloadable_files, File.expand_path('../../forge_build', __dir__))
    refute files.any? { |path| path.end_with?('/services/update_service.rb') }
    assert files.any? { |path| path.end_with?('/ui/main_dialog.rb') }
  end
end
