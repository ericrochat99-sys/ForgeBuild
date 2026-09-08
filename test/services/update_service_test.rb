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
end
