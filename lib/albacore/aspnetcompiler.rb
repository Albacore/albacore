require "albacore/albacoretask"
require "albacore/config/aspnetcompilerconfig"
require "albacore/support/platform"

class AspNetCompiler
  TaskName = :aspnetcompiler

  include Albacore::Task
  include Albacore::RunCommand
  include Configuration::AspNetCompiler
  include Albacore::Support
  
  attr_reader   :clean,
                :delay_sign,
                :fixed_names,
                :force,
                :updateable,
                :debug,
                :no_logo

  attr_accessor :physical_path, 
                :target_path, 
                :virtual_path

  def initialize
    @virtual_path = "/"
    super()
    update_attributes(aspnetcompiler.to_hash)
  end

  def execute    
    result = run_command("AspNetCompiler", build_parameters)
    fail_with_message("AspNetCompiler failed, see the build log for more details.") unless result
  end

  def build_parameters
    p = []
    p << "-v #{@virtual_path}" if @virtual_path
    p << "-p #{Platform.format_path(@physical_path)}" if @physical_path
    p << "-c" if @clean
    p << "-delaysign" if @delay_sign
    p << "-fixednames" if @fixed_names
    p << "-d" if @debug
    p << "-u" if @updateable
    p << "-f" if @force
    p << "-nologo" if @no_logo
    p << Platform.format_path(@target_path) if @target_path
    p
  end
  
  def updateable
    @updateable = true
  end
  
  def force
    @force = true
  end
  
  def clean
    @clean = true
  end
  
  def debug
    @debug = true
  end
  
  def delay_sign
    @delay_sign = true
  end
  
  def fixed_names
    @fixed_names = true
  end

  def no_logo
    @no_logo = true
  end
end
