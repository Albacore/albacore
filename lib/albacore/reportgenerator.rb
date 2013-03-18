require 'albacore/albacoretask'

class ReportGenerator
	include Albacore::Task
	include Albacore::RunCommand

	attr_accessor :reports, :target_dir, :report_types,
				  :source_dirs, :filters, :verbosity

	def execute
		command_parameters = []
		command_parameters << "\"-reports:#{reports.join(";")}\"" unless reports.nil?
		command_parameters << "\"-targetdir:#{target_dir}\"" unless target_dir.nil?
		command_parameters << "-reporttypes:#{report_types.join(";")}"
		command_parameters << "\"-sourcedirs:#{source_dirs.join(";")}\""
		command_parameters << "\"-filters:#{filters.join(";")}\""
		command_parameters << "-verbosity:#{verbosity}"

		result = run_command "ReportGenerator", command_parameters.join(" ")

		fail_with_message "Code coverage report generation failed." if !result
	end
end