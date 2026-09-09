# frozen_string_literal: true

require 'csv'
require 'json'
require 'fileutils'
require 'cgi'

module ForgeBuild
  module Services
    # Writes a self-contained commercial delivery package for estimating and coordination.
    class ExportService
      def initialize(information:) = @information = information

      def export(model:, directory:, options: {})
        report = @information.report(model: model,
                                     waste_factors: options[:waste_factors] || options['waste_factors'] || {},
                                     alternates: options[:alternates] || options['alternates'] || {},
                                     allowances: options[:allowances] || options['allowances'] || {})
        root = File.join(directory, safe_name(model.respond_to?(:title) ? model.title : 'ForgeBuild'), Time.now.utc.strftime('%Y%m%d-%H%M%S'))
        FileUtils.mkdir_p(root)
        write_csv(File.join(root, 'quantity_takeoff.csv'), flatten_takeoff(report[:takeoff]))
        write_csv(File.join(root, 'material_list.csv'), flatten_materials(report[:materials]))
        report[:schedules].each { |name, rows| write_csv(File.join(root, "schedule_#{safe_name(name)}.csv"), flatten_rows(rows)) }
        write_csv(File.join(root, 'validation_report.csv'), report[:validations] + report[:missing_information])
        write_csv(File.join(root, 'clash_warnings.csv'), report[:clashes])
        write_csv(File.join(root, 'classification_ifc_dwg.csv'), report[:classifications])
        File.write(File.join(root, 'ForgeBuild_Workbook.xml'), spreadsheet_xml(report))
        File.write(File.join(root, 'assembly_summary.json'), JSON.pretty_generate(serializable(report)))
        root
      end

      private

      def flatten_takeoff(rows)
        rows.flat_map { |row| expand_quantities(row) }
      end

      def flatten_materials(rows)
        rows.flat_map { |row| expand_quantities(row) }
      end

      def flatten_rows(rows)
        rows.map do |row|
          row.reject { |key, _| %i[dimensions quantities].include?(key) }
             .merge(prefix_hash(row[:dimensions], 'dimension'), prefix_hash(row[:quantities], 'quantity'))
        end
      end

      def expand_quantities(row)
        quantities = row[:quantities]
        return [row] if quantities.nil? || quantities.empty?
        quantities.map { |unit, value| row.reject { |key, _| key == :quantities }.merge(unit: unit, quantity: value.round(4)) }
      end

      def prefix_hash(hash, prefix)
        (hash || {}).each_with_object({}) { |(key, value), result| result["#{prefix}_#{key}"] = value }
      end

      def write_csv(path, rows)
        rows = Array(rows)
        headers = rows.flat_map(&:keys).uniq
        CSV.open(path, 'wb') do |csv|
          csv << headers
          rows.each { |row| csv << headers.map { |header| cell(row[header]) } }
        end
      end

      def spreadsheet_xml(report)
        sheets = { 'Takeoff' => flatten_takeoff(report[:takeoff]), 'Materials' => flatten_materials(report[:materials]),
                   'Validation' => report[:validations] + report[:missing_information], 'Clashes' => report[:clashes] }
        sheets.merge!(report[:schedules].transform_values { |rows| flatten_rows(rows) })
        body = sheets.map { |name, rows| worksheet(name, rows) }.join
        %(<?xml version="1.0"?><Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet" xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">#{body}</Workbook>)
      end

      def worksheet(name, rows)
        rows = Array(rows)
        headers = rows.flat_map(&:keys).uniq
        table = ([headers] + rows.map { |row| headers.map { |header| cell(row[header]) } }).map do |values|
          '<Row>' + values.map { |value| "<Cell><Data ss:Type=\"String\">#{CGI.escapeHTML(value.to_s)}</Data></Cell>" }.join + '</Row>'
        end.join
        "<Worksheet ss:Name=\"#{CGI.escapeHTML(name[0, 31])}\"><Table>#{table}</Table></Worksheet>"
      end

      def cell(value) = value.is_a?(Hash) || value.is_a?(Array) ? JSON.generate(value) : value
      def serializable(value)
        case value
        when Hash then value.each_with_object({}) { |(key, item), result| result[key] = serializable(item) unless key == :entity }
        when Array then value.map { |item| serializable(item) }
        else value
        end
      end
      def safe_name(value) = value.to_s.strip.gsub(/[^A-Za-z0-9_-]+/, '_').sub(/^_+|_+$/, '').then { |name| name.empty? ? 'ForgeBuild' : name }
    end
  end
end
