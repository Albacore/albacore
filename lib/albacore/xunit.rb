require "albacore/albacoretask"
require "albacore/config/xunitconfig"

class XUnit
  TaskName = :xunit

  include Albacore::Task
  include Albacore::RunCommand
  include Configuration::XUnit

  attr_accessor :assembly
  
  attr_hash     :output_path
                
  def initialize()
    super()
    update_attributes(xunit.to_hash)
  end

  def execute()    		
    unless @assembly
      fail_with_message("xunit requires #assembly")
      return
    end
    
    result = run_command("xunit", build_parameters)
    fail_with_message("XUnit failed, see build log for details.") unless result
  end
  
  def build_parameters
    p = []  
    p << "\"#{@assembly}\""
    p << "/#{@output_path.first.first} \"#{@output_path.first.last}\"" if @output_path
    p
  end
  
  def build_command_line
    c = []
    c << @command
    c << build_parameters
    c << @parameters
    c
  end
end
