# frozen_string_literal: true

module ForgeBuild
  module Services
    class DrawingComparisonService
      def compare(model_objects:, recognized_features:)
        objects = Array(model_objects)
        features = Array(recognized_features)
        matched = features.select { |feature| match?(feature, objects) }
        unresolved = features - matched
        {
          recognized_count: features.length, matched_count: matched.length, unresolved_count: unresolved.length,
          unresolved: unresolved.map { |feature| issue(feature) },
          model_only: objects.reject { |object| represented?(object, features) }.map { |object| model_issue(object) }
        }
      end

      private

      def match?(feature, objects)
        objects.any? do |object|
          object[:object_type].to_s == feature[:assembly].to_s ||
            (!feature[:tag].to_s.empty? && [object[:assembly], object[:comments], object[:tag]].any? { |value| value.to_s.include?(feature[:tag].to_s) })
        end
      end
      def represented?(object, features) = features.any? { |feature| feature[:assembly].to_s == object[:object_type].to_s }
      def issue(feature) = { severity: 'warning', type: 'drawing_only', feature: feature, message: "Drawing feature is not modeled: #{feature[:annotation] || feature[:kind]}" }
      def model_issue(object) = { severity: 'info', type: 'model_only', id: object[:id], message: "Model object has no recognized drawing match: #{object[:assembly]}" }
    end
  end
end
