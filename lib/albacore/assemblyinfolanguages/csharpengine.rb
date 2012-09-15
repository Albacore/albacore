require 'albacore/assemblyinfolanguages/assemblyinfoengine'

class CSharpEngine < AssemblyInfoEngine
  def initialize
    @using       = "using"
    @start_token = "["
    @end_token   = "]"
    @assignment  = "="
    @statement_terminator  = ";"
  end
  
  def build_attribute_re(attr_name)
    /^\[assembly: #{attr_name}(.+)/  
  end
end