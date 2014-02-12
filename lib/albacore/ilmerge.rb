require "albacore/albacoretask"
require "albacore/config/ilmergeconfig"

class ILMerge
  TaskName = :ilmerge
  
  include Albacore::Task
  include Albacore::RunCommand
  include Configuration::ILMerge

  attr_accessor :out, 
                :target_platform

  attr_array    :assemblies

  def initialize
    @command = "ilmerge"
    
    super()
    update_attributes(ilmerge.to_hash)
  end

  def execute
    raise "ilmerge requires #out" unless @out
    raise "ilmerge requires #assemblies" unless @assemblies

    result = run_command("ILMerge", build_parameters)
    fail_with_message("ILMerge failed, see the build log for more details.") unless result
  end

  def build_parameters  
    p = []
    p << "/out:\"#{@out}\""
    p << "/targetPlatform:#{@target_platform}" if @target_platform
    p << @assemblies.map { |asm| "\"#{asm}\"" } if @assemblies
    p
  end
end
