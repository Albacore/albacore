require 'albacore/albacoretask'
require 'albacore/support/supportlinux'

class NuGetInstall
	include Albacore::Task
 	include Albacore::RunCommand
 	include SupportsLinuxEnvironment

 	attr_accessor	:command,
                :package,
                :output_directory,
                :version,
                :exclude_version,
                :prerelease,
                :no_cache

	attr_array :sources

	def initialize(command='NuGet.exe')
		super()
		@sources = []
		@command = command
		@no_cache = false
		@prerelease = false
		@exclude_version = false
	end

	def execute
		params = generate_params

		@logger.debug "Build NuGet Install Command Line: #{params}"
		result = run_command "NuGet", params

		failure_message = "Nuget Install for package #{@package} failed. See Build log for details."
		fail_with_message failure_message unless result
	end

	def generate_params
		fail_with_message 'A NuGet package must be specified.' unless @package

		params = []
		params << 'install'
		params << package
		params << "-Version #{version}" if @version
		params << "-OutputDirectory #{output_directory}" if @output_directory
		params << "-ExcludeVersion" if @exclude_version
		params << "-NoCache" if @no_cache
		params << "-Prerelease" if @prerelease
		params << "-Source #{build_package_sources}" if @sources unless @sources.empty?

		merged_params = params.join(' ')
	end

	def build_package_sources
		"\"#{@sources.join(';')}\""
	end
end