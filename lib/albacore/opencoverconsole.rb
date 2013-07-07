require 'albacore/albacoretask'

class OpenCoverConsole
	include Albacore::Task
	include Albacore::RunCommand

	attr_accessor :target, :target_dir, :target_args, :output,
				  :filter, :register, :old_style, :merge_by_hash,
				  :no_default_filters, :return_target_code

	def execute
		raise ArgumentError if target.to_s.empty?

		command_parameters = []
		command_parameters << "\"-target:#{target}\"" 
		command_parameters << "\"-targetdir:#{target_dir}\"" unless target_dir.to_s.empty?
		command_parameters << "\"-targetargs:#{target_args}\"" unless target_args.to_s.empty?
		command_parameters << "\"-output:#{output}\"" unless output.to_s.empty?
		command_parameters << "\"-filter:#{filter}\"" unless filter.to_s.empty?
		command_parameters << "\"-register:#{register}\"" unless register.to_s.empty?
		command_parameters << "-oldStyle" if old_style
		command_parameters << "-mergebyhash" if merge_by_hash
		command_parameters << "-nodefaultfilters" if no_default_filters
		command_parameters << "-returntargetcode" if return_target_code
		
		result = run_command "OpenCover.Console", command_parameters.join(" ")

		fail_with_message "OpenCover analysis failed." if !result
	end
end