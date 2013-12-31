require "albacore/albacoretask"
require "albacore/config/xunitconfig"

class XUnit
  TaskName = :xunit

  include Albacore::Task
  include Albacore::RunCommand
  include Configuration::XUnit

  attr_reader   :continue_on_error

  attr_hash     :output_path
                
  attr_array    :assemblies

  def initialize()
    super()
    update_attributes(xunit.to_hash)
  end

  def execute()    		
    unless @assemblies
      fail_with_message("xunit requires #assemblies")
      return
    end
    
    # xunit supports only one test-assembly at a time
    @assemblies.each_with_index do |asm, index|
      result = run_command("xunit", build_parameters(asm, index, @assemblies.count > 1))
      fail_with_message("XUnit failed, see build log for details.") unless (result || @continue_on_error)
    end       
  end
  
  def build_parameters(assembly, index, multiple = false)
    p = []  
    p << "\"#{assembly}\""
    p << build_output_path(index, multiple) if @output_path
    p
  end
  
  def continue_on_error
    @continue_on_error = true
  end
  
  def build_output_path(index, multiple = false)
    type, path = @output_path.first
    
    dir = File.dirname(path)
    ext = File.extname(path)
    base = File.basename(path, ext)

    multiple ? 
      "/#{type} \"#{File.join(dir, "#{base}_#{index + 1}#{ext}")}\"" : 
      "/#{type} \"#{path}\"" 
  end
end
