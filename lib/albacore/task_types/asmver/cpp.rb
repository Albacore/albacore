require 'albacore/asmver/engine'

module Albacore::Asmver
  class CppCliEngine < Engine
    def initialize
      @start_token = "["
      @end_token   = "]"
      @assignment  = "="
      @statement_terminator  = ";"
    end

    def build_attribute_re(attr_name)
      /^\[assembly: #{attr_name}(.+)/  
    end
    
    def build_using_statement(namespace)
      "using namespace #{namespace.gsub(/\./, '::')};"
    end
  end
end
