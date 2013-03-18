require 'albacore/albacoretask'

class OpenCoverConsole
	include Albacore::Task
	include Albacore::RunCommand

	attr_accessor :target, :target_dir, :target_args, :output,
				  :filter, :register, :old_style, :merge_by_hash,
				  :no_default_filters, :return_target_code

	def execute
		command_parameters = []
		command_parameters << "\"-target:#{target}\"" unless target.nil?
		command_parameters << "\"-targetdir:#{target_dir}\"" unless target_dir.nil?
		command_parameters << "\"-targetargs:#{target_args}\"" unless target_args.nil?
		command_parameters << "\"-output:#{output}\"" unless output.nil?
		command_parameters << "\"-filter:#{filter}\"" unless filter.nil?
		command_parameters << "\"-register:#{register}\"" unless register.nil?
		command_parameters << "-oldStyle" if old_style
		command_parameters << "-mergebyhash" if merge_by_hash
		command_parameters << "-nodefaultfilters" if no_default_filters
		command_parameters << "-returntargetcode" if return_target_code
		
		result = run_command "OpenCover.Console", command_parameters.join(" ")

		fail_with_message "OpenCover analysis failed." if !result
	end
end