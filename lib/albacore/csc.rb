require "albacore/albacoretask"
require "albacore/config/cscconfig"
require "albacore/support/platform"

class CSC
  TaskName = :csc

  include Albacore::Task
  include Albacore::RunCommand
  include Configuration::CSC
  include Albacore::Support
  
  attr_reader   :debug,
                :optimize,
                :delay_sign,
                :no_logo

  attr_accessor :out, 
                :target, 
                :doc, 
                :main,
                :key_file, 
                :key_container
    
  attr_array    :compile, 
                :references, 
                :resources, 
                :define

  def initialize
    super()
    update_attributes(csc.to_hash)
  end

  def execute
    result = run_command("CSC", build_parameters)
    fail_with_message("CSC failed, see the build log for more details.") unless result
  end

  def build_parameters
    p = []
    p << @references.map { |ref| "/reference:#{Platform.format_path(ref)}" } if @references
    p << @resources.map { |res| "/resource:#{Platform.format_path(res)}" } if @resources
    p << "/main:#{@main}" if @main
    p << "/out:#{Platform.format_path(@out)}" if @out
    p << "/target:#{@target}" if @target
    p << "/optimize+" if @optimize
    p << "/keyfile:#{Platform.format_path(@key_file)}" if @key_file
    p << "/keycontainer:#{@key_container}" if @key_container
    p << "/delaysign+" if @delay_sign
    p << "/debug#{":#{@debug_type}" if @debug_type}" if @debug
    p << "/doc:#{Platform.format_path(@doc)}" if @doc
    p << "/define:#{@define.join(";")}" if @define
    p << "/nologo" if @no_logo
    p << @compile.map { |file| Platform.format_path(file) } if @compile
    p
  end

  def debug(type = nil)
    @debug = true
    @debug_type = type
  end
  
  def optimize
    @optimize = true
  end
  
  def delay_sign
    @delay_sign = true
  end

  def no_logo
    @no_logo = true
  end
end
