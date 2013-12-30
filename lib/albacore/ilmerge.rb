require "albacore/albacoretask"
require "albacore/config/ilmergeconfig"

class IlMerge
  TaskName = :ilmerge

  PLATFORMS = [ENV["PROGRAMFILES"], ENV["PROGRAMFILES(X86)"]]
  
  include Albacore::Task
  include Albacore::RunCommand
  include Configuration::ILMerge

  attr_accessor :output, 
                :target_platform

  attr_array    :assemblies

  def initialize
    @command = default_command
    super()
    update_attributes(ilmerge.to_hash)
  end

  def execute
    raise "ilmerge requires #output" unless @output
    raise "ilmerge requires #assemblies" unless @assemblies

    result = run_command("ILMerge", build_parameters)
    fail_with_message("ILMerge failed, see the build log for more details.") unless result
  end

  def build_parameters  
    p = []
    p << "/out:\"#{output}\""
    p << "/targetPlatform:#{target_platform}" if @target_platform
    p << @assemblies.map { |asm| "\"#{asm}\"" } if @assemblies
    p
  end

  def default_command
    PLATFORMS.map { |env| File.join(env.gsub("\\", "/"), "Microsoft/ILMerge/ilmerge.exe") if env }.find { |file| File.exists?(file) }
  end
end
