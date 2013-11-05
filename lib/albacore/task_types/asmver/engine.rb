module Albacore::Asmver
  class Engine
    def build_attribute attr_name, attr_data
      attribute = "#{@start_token}assembly: #{attr_name}("
      
      if attr_data
        if attr_data.is_a? Hash
          # Only named parameters
          attribute << build_named_parameters(attr_data)
        elsif attr_data.is_a? Array
          if attr_data.last.is_a? Hash
            # Positional and named parameters
            attribute << build_positional_parameters(attr_data.slice(0, attr_data.length - 1))
            attribute << ", "
            attribute << build_named_parameters(attr_data.last)
          else
            # Only positional parameters
            attribute << build_positional_parameters(attr_data)
          end
        else
          # Single positional parameter
          attribute << "#{attr_data.to_s}"
        end
      end
      
      attribute << ")#{@end_token}"
    end
    
    def build_named_parameters data
      params = []
      data.each_pair do |k, v|
        params << "#{k.to_s} #{@assignment} #{v.to_s}"
      end
      params.join ", "
    end
    
    def build_positional_parameters data
      data.flatten.map{ |a| a.to_s }.join(", ")
    end

    def build_using_statement namespace
      "#{@using} #{namespace}#{@statement_terminator}"
    end

    # builds a comment, as a single line if it's a single line
    # otherwise builds a multiline comment
    def build_comment string_data
      if is_multiline string_data
        build_multiline_comment string_data
      else
        build_singleline_comment string_data
      end
    end

    private

    NL = /\r\n?|\n/

    def is_multiline str
      str =~ NL
    end

    def comment_singleline_token
      '//'
    end

    def comment_multiline_start
      '/*'
    end

    def comment_multiline_end
      '*/'
    end

    def build_multiline_comment string_data
      comment_multiline_start + "\n" +
        string_data.split(NL).map{ |s| " " + s }.join("\n") + "\n" +
        comment_multiline_end
    end

    def build_singleline_comment string_data
      %Q|#{comment_singleline_token} #{string_data}|
    end
  end
end
