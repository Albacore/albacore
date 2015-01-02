module Albacore::Asmver
  class Engine
    def build_attribute attr_name, attr_data
      attribute = "#{@start_token}assembly: #{format_attribute_name attr_name}("

      unless attr_data.nil?
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
          attribute << "#{format_value attr_data}"
        end
      end

      attribute << ")#{@end_token}"
    end

    def build_named_parameters data
      params = []
      data.each_pair do |k, v|
        params << "#{k.to_s} #{@assignment} #{format_value v}"
      end
      params.join ", "
    end

    def build_positional_parameters data
      data.flatten.map{ |a| format_value a }.join(", ")
    end

    def build_using_statement namespace
      "#{@using} #{namespace}#{@statement_terminator}"
    end

    def build_namespace namespace, writer, &in_namespace
      raise ArgumentError, "missing block to #build_namespace on #{self.inspect}" unless block_given?
      writer << namespace_start(namespace)
      in_namespace.call namespace
      writer << namespace_end
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

    protected

    NL = /\r\n?|\n/

    # For formatting

    # formats what might be a snake_case attribute, in CamelCase.
    def format_attribute_name name
      return name if name !~ /_/ && name =~ /[A-Z]+.*/
      name.split('_').map{ |e| e.capitalize }.join 
    end

    # formats a value according to its type to make it more rubyesque
    def format_value v
      case v
      when String
        v.inspect
      when TrueClass
        'true'
      when FalseClass
        'false'
      else
        v.to_s
      end
    end

    # For namespaces

    def namespace_start namespace
      "namespace #{namespace} {"
    end

    def namespace_end
      "}" 
    end

    # For comments

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
