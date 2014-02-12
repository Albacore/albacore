require "albacore/albacoretask"
require "albacore/config/mspecconfig"

class MSpec
  TaskName = :mspec
  
  include Albacore::Task
  include Albacore::RunCommand
  include Configuration::MSpec

  attr_array    :assemblies
  
  attr_hash     :results_path
  
  def initialize()
    super()
    update_attributes(mspec.to_hash)
  end
  
  def execute()
    result = run_command("MSpec", build_parameters)
    fail_with_message("MSpec failed, see the build log for more details.") unless result
  end
  
  def build_parameters
    p = []
    p << @assemblies.map { |asm| "\"#{asm}\"" } if @assemblies
    p << "--#{@results_path.first.first} \"#{@results_path.first.last}\"" if @results_path
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
