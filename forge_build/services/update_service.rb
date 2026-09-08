# frozen_string_literal: true

module ForgeBuild
  module Services
    # Queries the official GitHub Releases feed and reports newer RBZ packages.
    class UpdateService
      RELEASE_API = 'https://api.github.com/repos/ericrochat99-sys/ForgeBuild/releases/latest'

      def initialize(current_version:)
        @current_version = current_version
      end

      # Checks asynchronously and yields a UI-safe result hash.
      def check(&callback)
        request = Sketchup::Http::Request.new(RELEASE_API, Sketchup::Http::GET)
        request.headers = {
          'Accept' => 'application/vnd.github+json',
          'User-Agent' => "ForgeBuild/#{@current_version}"
        }
        request.start { |_request, response| callback.call(parse_response(response)) }
      rescue StandardError => error
        callback.call(status: 'error', message: error.message)
      end

      private

      def parse_response(response)
        return { status: 'error', message: "GitHub returned HTTP #{response.status_code}" } unless response.status_code == 200

        release = JSON.parse(response.body)
        latest = release.fetch('tag_name').sub(/\Av/i, '')
        return { status: 'current', version: @current_version } unless newer?(latest, @current_version)

        asset = Array(release['assets']).find { |item| item['name'].to_s.downcase.end_with?('.rbz') }
        {
          status: 'available',
          version: latest,
          download_url: asset && asset['browser_download_url'],
          release_url: release['html_url']
        }
      rescue JSON::ParserError, KeyError => error
        { status: 'error', message: "Invalid release response: #{error.message}" }
      end

      def newer?(candidate, installed)
        (normalize(candidate) <=> normalize(installed)) == 1
      end

      def normalize(version)
        version.to_s.split('.').first(3).map { |part| Integer(part, 10) }.fill(0, 3)
      rescue ArgumentError
        [0, 0, 0]
      end
    end
  end
end
