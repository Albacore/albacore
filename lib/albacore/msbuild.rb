require "albacore/albacoretask"
require "albacore/config/msbuildconfig"

class MSBuild
  TaskName = :msbuild

  include Albacore::Task
  include Albacore::RunCommand
  include Configuration::MSBuild
  
  attr_reader   :no_logo
  
  attr_accessor :solution, 
                :verbosity, 
                # 'logger' property already exists in parent
                :logger_module 
  
  attr_array    :targets
  
  attr_hash     :properties, 
                :other_switches
  
  def initialize
    @command = "msbuild"
    
    super()
    update_attributes(msbuild.to_hash)
  end
  
  def execute
    unless @solution
      fail_with_message("msbuild requires #solution")
      return
    end

    result = run_command("MSBuild", build_parameters)
    fail_with_message("MSBuild failed, see the build log for more details.") unless result
  end
  
  def build_parameters()
    p = []
    p << "\"#{@solution}\""
    p << "/verbosity:#{@verbosity}" if @verbosity
    p << "/logger:\"#{@logger_module}\"" if @logger_module
    p << "/nologo" if @no_logo
    p << @properties.map { |key, value| "/property:#{key}\=\"#{value}\"" } if @properties
    p << @other_switches.map { |key, value| "/#{key}:\"#{value}\"" } if @other_switches
    p << "/target:\"#{@targets.join(";")}\"" if @targets
    p
  end

  def no_logo
    @no_logo = true
  end
end
