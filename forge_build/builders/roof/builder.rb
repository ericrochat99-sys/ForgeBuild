# frozen_string_literal: true

module ForgeBuild
  module Builders
    module Roof
      # Registered now so navigation and stored assembly identities remain stable
      # while roof geometry is delivered in the next milestone.
      class Builder < Core::Builder
        def id = :roof
        def name = 'Roof Builder'
        def divisions = %w[05 06 07].freeze
      end
    end
  end
end
