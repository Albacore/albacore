require "albacore/albacoretask"
require "albacore/config/nantconfig"

class NAnt 
  TaskName = :nant

  include Albacore::Task
  include Albacore::RunCommand

  attr_reader   :no_logo
  
  attr_accessor :build_file
  
  attr_array    :targets
  
  attr_hash     :properties
  
  def initialize
    super()
    update_attributes(Albacore.configuration.nant.to_hash)
  end
  
  def execute
    result = run_command("NAnt", build_parameters)
    fail_with_message("NAnt failed, see the build log for more details.") unless result
  end
  
  def build_parameters
    p = []
    p << "-buildfile:\"#{@build_file}\"" if @build_file
    p << @properties.map { |key, value| "-D:#{key}=\"#{value}\"" } if @properties
    p << @targets if @targets
    p << "-nologo" if @no_logo
    p
  end
  
  def no_logo
    @no_logo = true
  end
end
