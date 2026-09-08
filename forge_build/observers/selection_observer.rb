# frozen_string_literal: true

module ForgeBuild
  module Observers
    class SelectionObserver < Sketchup::SelectionObserver
      def initialize(&callback) = @callback = callback
      def onSelectionBulkChange(selection) = @callback.call(selection)
      def onSelectionCleared(selection) = @callback.call(selection)
      def onSelectionAdded(selection, _entity) = @callback.call(selection)
      def onSelectionRemoved(selection, _entity) = @callback.call(selection)
    end
  end
end
