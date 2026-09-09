# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'
require 'digest'

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

      # Downloads, replaces, and installs the latest trusted GitHub RBZ.
      def install(update, &callback)
        url = update[:download_url].to_s
        return callback.call(status: 'error', message: 'This release has no RBZ download.') if url.empty?

        @download_request = Sketchup::Http::Request.new(url, Sketchup::Http::GET)
        @download_request.headers = { 'Accept' => 'application/octet-stream',
                                      'User-Agent' => "ForgeBuild/#{@current_version}" }
        @download_request.start do |_request, response|
          result = response.status_code == 200 ? install_response(response.body, update[:version], update[:digest]) :
                   { status: 'error', message: "Download returned HTTP #{response.status_code}" }
          callback.call(result)
          @download_request = nil
        end
      rescue StandardError => error
        @download_request = nil
        callback.call(status: 'error', message: error.message)
      end

      private

      def install_response(body, version, digest = nil)
        raise 'The downloaded file is not a valid RBZ archive.' unless valid_archive?(body)
        if digest && !digest.to_s.empty?
          expected = digest.to_s.sub(/\Asha256:/i, '')
          raise 'The downloaded RBZ failed its SHA-256 integrity check.' unless Digest::SHA256.hexdigest(body) == expected
        end

        Dir.mktmpdir('forgebuild-update-') do |directory|
          archive = File.join(directory, "ForgeBuild-v#{version}.rbz")
          File.binwrite(archive, body)
          replace_install(archive, directory)
        end
        { status: 'installed', version: version,
          message: "ForgeBuild #{version} is installed. Restart SketchUp to activate all changes." }
      rescue StandardError => error
        { status: 'error', message: "Update failed; the previous version was restored. #{error.message}" }
      end

      def replace_install(archive, temporary_directory)
        plugins = nil
        backup = nil
        plugins = Sketchup.find_support_file('Plugins')
        raise 'SketchUp Plugins folder was not found.' if plugins.to_s.empty?

        backup = File.join(temporary_directory, 'backup')
        FileUtils.mkdir_p(backup)
        installed_paths(plugins).each { |path| FileUtils.mv(path, backup) if File.exist?(path) }

        success = Sketchup.install_from_archive(archive, false)
        raise 'SketchUp rejected the downloaded extension.' unless success
      rescue StandardError
        installed_paths(plugins).each { |path| FileUtils.rm_rf(path) if File.exist?(path) } if plugins
        restore_backup(backup, plugins) if plugins && backup && File.directory?(backup)
        raise
      end

      def restore_backup(backup, plugins)
        Dir.children(backup).each { |name| FileUtils.mv(File.join(backup, name), plugins) }
      end

      def installed_paths(plugins)
        [File.join(plugins, 'forge_build.rb'), File.join(plugins, 'forge_build')]
      end

      def valid_archive?(body)
        body.is_a?(String) && body.bytesize > 100 && body.start_with?("PK\x03\x04".b)
      end

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
          digest: asset && asset['digest'],
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
