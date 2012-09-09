# Albacore task for installing NuGet packages

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

	attr_array		:sources

	def initialize(command="NuGet.exe")
		super()
		@sources = []
		@command = command
		@no_cache = false
		@prerelease = false
		@exclude_version = false
	end

	def execute
		params = generate_params

		@logger.debug "Build NuGet Install Command Line: #{merged_params}"
		result = run_command "NuGet", params

		failure_message = "Nuget Install for package #{@package} failed. See Build log for details."
		fail_with_message failure_message if !result
	end

	def generate_params
		fail_with_message 'A NuGet package must be specified.' if @package.nil?

		params = []
		params << "install"
		params << package
		params << "-Version #{version}" unless @version.nil?
		params << "-OutputDirectory #{output_directory}" unless @output_directory.nil?
		params << "-ExcludeVersion" if @exclude_version
		params << "-NoCache" if @no_cache
		params << "-Prerelease" if @prerelease
		params << "-Source #{build_package_sources}" unless @sources.nil? || @sources.empty?

		merged_params = params.join(' ')
	end

	def build_package_sources
		"\"#{@sources.join(';')}\""
	end
end