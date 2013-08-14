require 'albacore/asmver/engine'

module Albacore::Asmver
  class Vb < Engine
    def initialize
      @using       = "Imports"
      @start_token = "<"
      @end_token   = ">"
      @assignment  = ":="
      @statement_terminator  = ""
    end
    
    def build_attribute_re(attr_name)
      /^\<assembly: #{attr_name}(.+)/i  
    end
  end
end
