require "albacore/albacoretask"
require "albacore/config/ncoverconsoleconfig"

class NCoverConsole
  TaskName = :ncoverconsole

  include Albacore::Task
  include Albacore::RunCommand
  include Configuration::NCoverConsole

  attr_reader   :register
  
  attr_accessor :test_runner

  attr_array    :include_assemblies, 
                :exclude_assemblies, 
                :include_attributes,
                :exclude_attributes,
                :coverage

  attr_hash     :output
  
  def initialize
    @register = true
    
    super()
    update_attributes(ncoverconsole.to_hash)
  end
  
  def execute
    unless @test_runner
      fail_with_message("ncoverconsole requires #test_runner")
      return
    end
    
    result = run_command("ncoverconsole", build_parameters)
    fail_with_message("NCover Console failed, see the build log for more details.") unless result
  end
  
  def build_parameters
    p = []
    p << "//reg" if @register
    p << @output.map { |key, value| "//#{key} \"#{value}\"" } if @output
    p << "//include-assemblies \"#{@include_assemblies.join(";")}\"" if @include_assemblies
    p << "//exclude-assemblies \"#{@exclude_assemblies.join(";")}\"" if @exclude_assemblies
    p << "//include-attributes \"#{@include_attributes.join(";")}\"" if @include_attributes
    p << "//exclude-attributes \"#{@exclude_attributes.join(";")}\"" if @exclude_attributes
    p << "//coverage-type \"#{@coverage.join(", ")}\"" if @coverage
    p << @test_runner.build_command_line
    p
  end
  
  def no_registration
    @register = false
  end
end
