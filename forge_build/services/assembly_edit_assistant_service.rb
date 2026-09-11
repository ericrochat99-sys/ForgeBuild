# frozen_string_literal: true

module ForgeBuild
  module Services
    # Turns a natural-language edit request into a guarded ForgeBuild assembly edit plan.
    # This is intentionally deterministic: it prepares safe parameter edits, warnings,
    # follow-up questions, and handoff context before any AI provider is connected.
    class AssemblyEditAssistantService
      LENGTH_PARAMETERS = %w[width length height thickness depth elevation sill_height end_height
                             edge_width edge_depth depression_depth span overhang bearing_length
                             seam_spacing spacing stud_spacing].freeze
      NUMERIC_PARAMETERS = %w[pitch slope r_value stc].freeze
      TEXT_PARAMETERS = %w[fire_rating ul_design ga_design smoke_rating security_class notes system material
                           framing insulation sheathing finish].freeze
      TOP_LEVEL_FIELDS = %w[assembly material finish tag comments fire_rating manufacturer model_number].freeze

      def initialize(assemblies:)
        @assemblies = assemblies
      end

      def analyze(selection:, request:, current_parameters: {})
        attributes = normalize_selection(selection)
        text = request.to_s.strip
        parameters = stringify_hash(current_parameters)
        changes = detect_changes(text, parameters)
        warnings = detect_warnings(text, attributes, changes)
        actions = recommended_actions(text, attributes, changes)
        questions = follow_up_questions(text, attributes, changes)
        apply_to_similar = text.match?(/\b(apply to similar|all similar|same type|all of these|every similar)\b/i)

        {
          object: object_label(attributes),
          request: text,
          changes: changes,
          detected_parameter_count: changes.fetch(:parameters, {}).length,
          detected_attribute_count: changes.fetch(:attributes, {}).length,
          apply_to_similar: apply_to_similar,
          warnings: warnings,
          actions: actions,
          questions: questions,
          safety: safety_level(warnings),
          prompt: build_prompt(text, attributes, parameters, changes, warnings, questions)
        }
      end

      def apply(entity:, plan:, model: Sketchup.active_model)
        raise ArgumentError, 'Select a ForgeBuild assembly before applying an assisted edit.' unless entity

        normalized = normalize_plan(plan)
        targets = normalized[:apply_to_similar] ? similar_entities(model, entity) : [entity]
        targets.each { |target| @assemblies.edit(target, normalized[:changes], model: model) }
        {
          applied_count: targets.length,
          apply_to_similar: normalized[:apply_to_similar],
          changed_parameters: normalized[:changes].fetch('parameters', {}).keys,
          changed_attributes: normalized[:changes].keys - ['parameters']
        }
      end

      private

      def normalize_selection(selection)
        case selection
        when Hash then selection.transform_keys(&:to_s)
        else {}
        end
      end

      def stringify_hash(hash)
        case hash
        when Hash then hash.each_with_object({}) { |(key, value), result| result[key.to_s] = value }
        else {}
        end
      end

      def object_label(attributes)
        builder = attributes['builder'] || 'assembly'
        type = attributes['object_type'] || 'selected object'
        "#{builder} / #{type}"
      end

      def detect_changes(text, current_parameters)
        lower = text.downcase
        parameter_changes = {}
        attribute_changes = {}

        add_length(parameter_changes, 'height', text, /(?:height|high|tall|wall height)\D{0,16}(-?\d+(?:\.\d+)?\s*(?:'|ft|feet)?\s*-?\s*\d*(?:\"|in|inch|inches)?)/i)
        add_length(parameter_changes, 'height', text, /(-?\d+(?:\.\d+)?\s*(?:'|ft|feet))\s*(?:high|tall)/i)
        add_length(parameter_changes, 'thickness', text, /(?:thickness|thick|wall type|cmu|stud)\D{0,22}(\d+(?:\.\d+)?\s*(?:\"|in|inch|inches)?)/i)
        add_length(parameter_changes, 'thickness', text, /(\d+(?:\.\d+)?\s*(?:\"|in|inch|inches))\s*(?:thick|cmu|stud)/i)
        add_length(parameter_changes, 'width', text, /(?:width|wide)\D{0,16}(-?\d+(?:\.\d+)?\s*(?:'|ft|feet|\"|in|inch|inches)?)/i)
        add_length(parameter_changes, 'length', text, /(?:length|long|run)\D{0,16}(-?\d+(?:\.\d+)?\s*(?:'|ft|feet|\"|in|inch|inches)?)/i)
        add_length(parameter_changes, 'elevation', text, /(?:elevation|level)\D{0,16}(-?\d+(?:\.\d+)?\s*(?:'|ft|feet|\"|in|inch|inches)?)/i)
        add_length(parameter_changes, 'depth', text, /(?:depth|deep)\D{0,16}(-?\d+(?:\.\d+)?\s*(?:'|ft|feet|\"|in|inch|inches)?)/i)

        if lower.match?(/\b(make|change|set)\b.*\b(8\s*(?:inch|in|\")?|8\s*cmu|eight inch)\b.*\bcmu\b/) || lower.match?(/\b8\s*(?:inch|in|\")?\s*cmu\b/)
          parameter_changes['thickness'] = 8.0
          parameter_changes['material'] = 'Concrete masonry'
        end
        if lower.match?(/\b(6\s*(?:inch|in|\")?|six inch)\b.*\bslab\b/)
          parameter_changes['thickness'] = 6.0
        end
        if lower.match?(/\b(4\s*(?:inch|in|\")?|four inch)\b.*\bslab\b/)
          parameter_changes['thickness'] = 4.0
        end

        fire = text.match(/(\d+)\s*(?:hr|hour|hours)\s*(?:fire|rated|rating)?/i)
        if fire
          attribute_changes['fire_rating'] = "#{fire[1]} hour"
          parameter_changes['fire_rating'] = "#{fire[1]} hour" if current_parameters.key?('fire_rating')
        end

        add_numeric(parameter_changes, 'stc', text, /stc\D{0,8}(\d+)/i)
        add_numeric(parameter_changes, 'r_value', text, /r[- ]?value\D{0,8}(\d+)/i)
        add_numeric(parameter_changes, 'r_value', text, /\br[- ]?(\d{1,3})\b/i)
        add_numeric(parameter_changes, 'pitch', text, /(?:pitch)\D{0,10}(\d+(?:\.\d+)?)/i)
        add_numeric(parameter_changes, 'slope', text, /(?:slope)\D{0,10}(\d+(?:\.\d+)?)/i)

        finish = text.match(/(?:finish|surface)\D{0,16}([a-z0-9 \-\/]+)/i)
        parameter_changes['finish'] = cleanup_text_value(finish[1]) if finish

        {
          parameters: filter_empty(parameter_changes),
          attributes: filter_top_level(attribute_changes)
        }
      end

      def add_length(result, key, text, pattern)
        match = text.match(pattern)
        return unless match
        value = parse_length(match[1])
        result[key] = value if value
      end

      def add_numeric(result, key, text, pattern)
        match = text.match(pattern)
        return unless match
        result[key] = Float(match[1])
      rescue StandardError
        nil
      end

      def parse_length(raw)
        text = raw.to_s.strip
        feet = text.match(/(-?\d+(?:\.\d+)?)\s*(?:'|ft|feet)(?:\s*-?\s*(\d+(?:\.\d+)?)\s*(?:\"|in|inch|inches)?)?/i)
        return (Float(feet[1]) * 12.0) + Float(feet[2] || 0) if feet

        inches = text.match(/(-?\d+(?:\.\d+)?)\s*(?:\"|in|inch|inches)/i)
        return Float(inches[1]) if inches

        number = text.match(/(-?\d+(?:\.\d+)?)/)
        number ? Float(number[1]) : nil
      rescue StandardError
        nil
      end

      def cleanup_text_value(value)
        value.to_s.strip.gsub(/[.,;:]\z/, '')
      end

      def filter_empty(hash)
        hash.reject { |_, value| value.nil? || value.to_s.strip.empty? || value.to_s == 'NaN' }
      end

      def filter_top_level(hash)
        hash.select { |key, _| TOP_LEVEL_FIELDS.include?(key.to_s) }
      end

      def detect_warnings(text, attributes, changes)
        warnings = []
        if text.match?(/door|window|opening|louver|storefront|borrowed lite|overhead/i)
          warnings << 'Use opening tools for doors, windows, louvers, storefront, and overhead doors; do not model openings by only changing wall dimensions.'
        end
        if changes.fetch(:parameters, {}).key?('thickness') && attributes['builder'].to_s == 'wall' && text.match?(/rated|fire|stc/i)
          warnings << 'Changing wall thickness can invalidate rated or acoustic assemblies; verify the UL/GA/STC basis before export.'
        end
        if text.match?(/apply to similar|all similar|same type|all of these|every similar/i)
          warnings << 'Apply-to-similar will update every ForgeBuild object with the same builder and object type in the active model.'
        end
        warnings
      end

      def recommended_actions(text, attributes, changes)
        actions = []
        actions << 'Apply detected parameter changes, then regenerate the assembly.' unless changes.fetch(:parameters, {}).empty?
        actions << 'Use Push/Pull Assembly to preview length, width, height, or thickness changes interactively.' if text.match?(/push|pull|stretch|extend|resize|longer|shorter|taller|higher/i)
        actions << 'Create openings with the opening builder or trace-opening tool before regenerating schedules.' if text.match?(/door|window|opening|louver|storefront|overhead/i)
        actions << 'Run Estimate & Reports after applying edits to refresh quantities and schedules.'
        actions << "Current target: #{object_label(attributes)}."
        actions
      end

      def follow_up_questions(text, _attributes, changes)
        questions = []
        questions << 'Which side or baseline should remain fixed during push/pull?' if text.match?(/push|pull|stretch|extend|resize/i)
        questions << 'Should this apply only to the selected assembly or to all similar assemblies?' unless text.match?(/selected only|apply to similar|all similar|same type/i)
        questions << 'What exact opening size and head/sill height are required?' if text.match?(/door|window|opening|louver|storefront|overhead/i)
        questions << 'What tested design reference should be stored?' if text.match?(/fire|rated|stc|acoustic|smoke/i)
        questions << 'Provide the target dimension or rating to create a direct parameter edit.' if changes.fetch(:parameters, {}).empty? && changes.fetch(:attributes, {}).empty?
        questions
      end

      def safety_level(warnings)
        warnings.empty? ? 'ready' : 'review_required'
      end

      def build_prompt(text, attributes, parameters, changes, warnings, questions)
        [
          'Review this ForgeBuild assembly edit request. Return compact JSON with safe_changes, warnings, questions, and recommended_workflow.',
          "Selected assembly: #{object_label(attributes)}",
          "Current parameters: #{parameters}",
          "Requested edit: #{text}",
          "Detected changes: #{changes}",
          "Warnings: #{warnings}",
          "Questions: #{questions}",
          'Do not create openings by changing wall dimensions only; use opening tools when required.'
        ].join("\n")
      end

      def normalize_plan(plan)
        raw = case plan
              when Hash then plan.transform_keys(&:to_s)
              else {}
              end
        raw_changes = raw['changes'] || {}
        raw_changes = raw_changes.transform_keys(&:to_s) if raw_changes.respond_to?(:transform_keys)
        attributes = stringify_hash(raw_changes['attributes'] || {})
        parameters = stringify_hash(raw_changes['parameters'] || {})
        {
          apply_to_similar: truthy?(raw['apply_to_similar']),
          changes: attributes.merge('parameters' => parameters)
        }
      end

      def truthy?(value)
        value == true || value.to_s.downcase == 'true' || value.to_s == '1'
      end

      def similar_entities(model, entity)
        source = Models::ParametricObject.read(entity)
        all_forge_build_entities(model.entities).select do |candidate|
          next false unless Models::ParametricObject.forge_build?(candidate)
          attributes = Models::ParametricObject.read(candidate)
          attributes[:builder].to_s == source[:builder].to_s && attributes[:object_type].to_s == source[:object_type].to_s
        end
      end

      def all_forge_build_entities(entities, results = [])
        entities.each do |entity|
          results << entity if entity.respond_to?(:get_attribute) && Models::ParametricObject.forge_build?(entity)
          if entity.respond_to?(:definition) && entity.definition.respond_to?(:entities)
            all_forge_build_entities(entity.definition.entities, results)
          elsif entity.respond_to?(:entities)
            all_forge_build_entities(entity.entities, results)
          end
        end
        results.uniq
      end
    end
  end
end
