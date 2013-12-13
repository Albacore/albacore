require "albacore/albacoretask"
require "albacore/config/docuconfig"

class Docu
  include Albacore::Task
  include Albacore::RunCommand
  include Configuration::Docu
  
  attr_accessor :output_path

  attr_array    :assemblies, 
                :xml_files
  
  def initialize(command=nil)
    super()
    update_attributes(docu.to_hash)
  end
  
  def execute
    unless @assemblies
      fail_with_message("docu requires #assemblies")
      return
    end
  
    result = run_command("docu", build_parameters)
    fail_with_message("Docu failed, see the build log for more details.") unless result
  end
  
  def build_parameters
    p = []
    p << @assemblies.map { |asm| "\"#{asm}\"" } if @assemblies
    p << @xml_files.map { |xml| "\"#{xml}\"" } if @xml_files
    p << " --output=\"#{@output_path}\" " if @output_path
    p
  end
end
