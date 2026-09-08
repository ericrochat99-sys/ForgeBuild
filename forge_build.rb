# frozen_string_literal: true

require 'sketchup.rb'
require 'extensions.rb'

module ForgeBuild
  EXTENSION_NAME = 'ForgeBuild'
  EXTENSION_ROOT = File.expand_path('forge_build', __dir__)

  unless file_loaded?(__FILE__)
    extension = SketchupExtension.new(EXTENSION_NAME, File.join(EXTENSION_ROOT, 'extension'))
    extension.description = 'Commercial building modeling tools for SketchUp.'
    extension.version = '0.3.0'
    extension.creator = 'ForgeBuild'
    extension.copyright = 'Copyright 2026 ForgeBuild. All rights reserved.'
    Sketchup.register_extension(extension, true)
    file_loaded(__FILE__)
  end
end
