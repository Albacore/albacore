require "albacore/albacoretask"
require "albacore/config/mspectestrunnerconfig"

class MSpecTestRunner
  TaskName = :mspec
  
  include Albacore::Task
  include Albacore::RunCommand
  
  attr_accessor :html_output

  attr_array    :assemblies
  
  def initialize()
    super()
    update_attributes(Albacore.configuration.mspec.to_hash)
  end
  
  def execute()
    result = run_command("MSpec", build_parameters)
    fail_with_message("MSpec failed, see the build log for more details.") unless result
  end
  
  def build_parameters
    p = []
    p << @assemblies.map { |asm| "\"#{asm}\"" } if @assemblies
    p << "--html \"#{@html_output}\"" if @html_output
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
