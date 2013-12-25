require "albacore/albacoretask"

class NUnitTestRunner
  TaskName = :nunit
  
  include Albacore::Task
  include Albacore::RunCommand
  
  attr_reader   :no_logo
  
  attr_accessor :results_path
  
  attr_array    :assemblies
  
  def initialize()
    super()
    update_attributes(Albacore.configuration.nunit.to_hash)
  end
  
  def execute()
    result = run_command("nunit", build_parameters)
    fail_with_message("NUnit failed, see the build log for more details.") unless result
  end
    
  def no_logo
    @no_logo = true
  end
    
  def build_parameters
    p = []
    p << @assemblies.map{ |asm| "\"#{asm}\"" } if @assemblies
    p << "/xml=\"#{@results_path}\"" if @results_path
    p << "/nologo" if @no_logo
    p
  end
end
