require 'albacore/task_types/asmver/engine'

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

    def namespace_start ns
      ""
    end

    def namespace_end
      ""
    end

    # override
    def comment_singleline_token
      '\''
    end

    # override
    def build_multiline_comment string_data
      string_data.split(NL).map { |s| "' " + s }.join("\n")
    end
  end
end
