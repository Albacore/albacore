require 'albacore/task_types/asmver/engine'

module Albacore::Asmver
  class Cpp < Engine
    def initialize
      @start_token = "["
      @end_token   = "]"
      @assignment  = "="
      @statement_terminator  = ";"
    end

    def build_attribute_re(attr_name)
      /^\[assembly: #{attr_name}(.+)/  
    end

    def namespace_start ns
      "namespace #{ns.gsub /\./, '::'} {"
    end

    def namespace_end
      "}\n"
    end
    
    def build_using_statement(namespace)
      "using namespace #{namespace.gsub(/\./, '::')};"
    end

  end
end
