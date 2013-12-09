require "albacore/albacoretask"

class NCoverConsole
  include Albacore::Task
  include Albacore::RunCommand

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
    update_attributes(Albacore.configuration.ncoverconsole.to_hash)
  end
  
  def execute
    unless @test_runner
      fail_with_message("ncoverconsole requires #test_runner")
      return
    end
    
    result = run_command("ncoverconsole", build_parameters)
    fail_with_message("NCover Console failed, see the build log for more details.") unless result
  end
  
  def no_registration
    @register = false
  end
  
  def build_parameters
    p = []
    p << "//reg" if @register
    p << @output.map { |key, value| "//#{key} #{value}" } if @output
    p << "//include-assemblies #{build_list(@include_assemblies)}" if @include_assemblies
    p << "//exclude-assemblies #{build_list(@exclude_assemblies)}" if @exclude_assemblies
    p << "//include-attributes #{build_list(@include_attributes)}" if @include_attributes
    p << "//exclude-attributes #{build_list(@exclude_attributes)}" if @exclude_attributes
    p << "//coverage-type \"#{@coverage.join(", ")}\"" if @coverage
    p << @test_runner.get_command_line
    p
  end

  def build_list(param_name, list)
    list.map{ |asm| "\"#{asm}\"" }.join(";")
  end
end
