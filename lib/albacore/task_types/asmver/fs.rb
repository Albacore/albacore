require 'albacore/task_types/asmver/engine'

module Albacore::Asmver
  class Fs < Engine
    def initialize
      @using       = "open"
      @start_token = "[<"
      @end_token   = ">]"
      @assignment  = "="
      @statement_terminator  = ""
    end

    def build_attribute_re(attr_name)
      /^\[\<assembly: #{attr_name}(.+)/
    end

    # namespaces

    def namespace_start ns
      "namespace #{ns}"
    end

    def namespace_end
      "()\n"
    end 

    # comments

    def comment_multiline_start
      '(*'
    end

    def comment_multiline_end
      '*)'
    end
  end
end
