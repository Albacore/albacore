require "albacore/albacoretask"

class XBuild
  TaskName = :xbuild

  include Albacore::Task
  include Albacore::RunCommand
  
  attr_accessor :solution, 
                :verbosity
  
  attr_array    :targets
  
  attr_hash     :properties
  
  def initialize
    @command = "xbuild"
    super()
    update_attributes(Albacore.configuration.xbuild.to_hash)
  end
  
  def execute
    unless @solution
      fail_with_message("xbuild requires #solution")
      return
    end
    
    result = run_command("xbuild", build_parameters)
    fail_with_message("XBuild failed, see the build log for more details.") unless result
  end
  
  def build_parameters
    p = []
    p << "\"#{solution}\""
    p << "/verbosity:#{@verbosity}" if @verbosity
    p << @properties.map { |key, value| "/p:#{key}\=\"#{value}\"" } if @properties
    p << "/target:#{@targets.join(";")}" if @targets
    p
  end
end
