require "albacore/albacoretask"
require "albacore/config/specflowreportconfig"

class SpecFlowReport
  include Albacore::Task
  include Albacore::RunCommand
  include Configuration::SpecFlowReport
  
  attr_accessor :report, 
                :project
  
  def initialize()
    super()
    update_attributes(specflowreport.to_hash)
  end
  
  def execute()
    result = run_command("specflow", build_parameters)
    fail_with_message("SpecFlow failed, see the build log for more details.") unless result
  end  
    	
  def build_parameters
    p = []
    p << @report
    p << "\"#{@project}\""
    p
  end
end
