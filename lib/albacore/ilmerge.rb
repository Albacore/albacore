require "albacore/albacoretask"
require "albacore/config/ilmergeconfig"

class IlMerge 
  TaskName = :ilmerge
  
  include Albacore::Task
  include Albacore::RunCommand
  include Configuration::ILMerge

  attr_accessor :output, 
                :target_platform

  attr_array    :assemblies

  def initialize
    super()
    update_attributes(ilmerge.to_hash)
  end

  def build_parameters
    raise "ilmerge requires #output" unless @output
    raise "ilmerge requires #assemblies" unless @assemblies
  
    p = []
    p << "/out:\"#{output}\""
    p << "/targetPlatform:#{target_platform}" if @target_platform
    p << @assemblies if @assemblies
    p
  end

  def execute
    @command ||= default_command
    result = run_command("ILMerge", build_parameters)
    fail_with_message("ILMerge failed, see the build log for more details.") unless result
  end
  
  def default_command
    [ENV["PROGRAMFILES"], ENV["PROGRAMFILES(X86)"]].map { |env| File.join(env.gsub("\\", "/"), "Microsoft/ILMerge/ilmerge.exe") if env }.find { |file| File.exists?(file) }
  end
end
