require 'albacore/task_types/asmver/engine'

module Albacore::Asmver
  class Cs < Engine
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

    # no namespaces
    def namespace_start *_
      ""
    end

    def namespace_end
      ""
    end
  end
end
