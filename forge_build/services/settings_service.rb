# frozen_string_literal: true

module ForgeBuild
  module Services
    # Persists small user preferences through SketchUp's defaults API.
    class SettingsService
      SECTION = 'ForgeBuild'

      # Reads a preference and returns the supplied default when absent.
      def get(key, default = nil)
        Sketchup.read_default(SECTION, key.to_s, default)
      end

      # Writes a preference value.
      def set(key, value)
        Sketchup.write_default(SECTION, key.to_s, value)
      end
    end
  end
end
