# frozen_string_literal: true

require 'fileutils'
require 'rake/testtask'

Rake::TestTask.new { |task| task.pattern = 'test/**/*_test.rb' }

desc 'Validate Ruby syntax'
task :syntax do
  files = FileList['forge_build.rb', 'forge_build/**/*.rb', 'test/**/*.rb', 'Rakefile']
  files.each { |file| abort("Syntax error: #{file}") unless system(RbConfig.ruby, '-c', file, out: File::NULL) }
end

desc 'Build installable RBZ archive'
task package: %i[syntax test] do
  FileUtils.mkdir_p('dist')
  archive = "dist/ForgeBuild-v#{File.read('forge_build/version.rb')[/VERSION = '([^']+)'/, 1]}.rbz"
  FileUtils.rm_f(archive)
  system('zip', '-qr', archive, 'forge_build.rb', 'forge_build') || abort('RBZ packaging failed')
  puts archive
end

task default: %i[syntax test]
