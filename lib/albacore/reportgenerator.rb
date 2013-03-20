require 'albacore/albacoretask'

class ReportGenerator
	include Albacore::Task
	include Albacore::RunCommand

	attr_accessor :reports, :target_dir, :report_types,
				  :source_dirs, :filters, :verbosity

	def execute
		valid_report_types = [:None, :Html, :HtmlSummary, :Xml, :XmlSummary, :Latex, :LatexSummary]
		valid_verbosity_levels = [:Verbose, :Info, :Error]

		raise ArgumentError if reports.to_a.empty? || target_dir.to_s.empty?
		raise ArgumentError if !report_types.nil? && report_types.any? { |t| !valid_report_types.include?(t) }
		raise ArgumentError if !verbosity.nil? && !valid_verbosity_levels.include?(verbosity)

		command_parameters = []
		command_parameters << "\"-reports:#{reports.to_a.join(";")}\"" 
		command_parameters << "\"-targetdir:#{target_dir}\"" 
		command_parameters << "-reporttypes:#{report_types.to_a.map(&:to_s).join(";")}" unless report_types.to_a.empty?
		command_parameters << "\"-sourcedirs:#{source_dirs.to_a.join(";")}\"" unless source_dirs.to_a.empty?
		command_parameters << "\"-filters:#{filters.to_a.join(";")}\"" unless filters.to_a.empty?
		command_parameters << "-verbosity:#{verbosity}" unless verbosity.to_s.empty?

		result = run_command "ReportGenerator", command_parameters.join(" ")

		fail_with_message "Code coverage report generation failed." if !result
	end
end