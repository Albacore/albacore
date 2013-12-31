require "albacore/albacoretask"
require "albacore/config/assemblyinfoconfig"
require "albacore/assemblyinfolanguages/assemblyinfoengine"
require "albacore/assemblyinfolanguages/cppcliengine"
require "albacore/assemblyinfolanguages/csharpengine"
require "albacore/assemblyinfolanguages/fsharpengine"
require "albacore/assemblyinfolanguages/vbnetengine"

class AssemblyInfo
  include Albacore::Task
  include Configuration::AssemblyInfo
  
  attr_reader   :com_visible
  
  attr_accessor :input_file, 
                :output_file, 
                :version, 
                :file_version, 
                :informational_version,
                :title, 
                :description, 
                :copyright, 
                :company_name, 
                :product_name,
                :trademark, 
                :com_guid, 
                :language,
                :lang_engine
  
  attr_array    :namespaces, 
                :custom_data, 
                :initial_comments
  
  attr_hash     :custom_attributes
  
  def initialize
    super()
    update_attributes(assemblyinfo.to_hash)
  end

  def execute
    unless @output_file
      fail_with_message("assemblyinfo requires #output_file")
      return
    end
    
    @lang_engine ||= AssemblyInfoEngine.from_language(@language)
    @custom_data ||= []
    @custom_attributes ||= {}
    @initial_comments ||= []
    @namespaces ||= []
    @namespaces << "System.Reflection"
    @namespaces << "System.Runtime.InteropServices"
    @namespaces.uniq!

    @logger.info "Generating AssemblyInfo file: #{File.expand_path(@output_file)}"

    input = @input_file ? read_input(@input_file) : []
    output = build(input)
    write_output(output)
  end

  def com_visible
    @com_visible = true
  end
  
  def build(data)
    data = build_header if data.empty?
    data = @initial_comments + build_using_statements(data) + data

    build_attribute(data, "AssemblyTitle", @title)
    build_attribute(data, "AssemblyDescription", @description)
    build_attribute(data, "AssemblyCompany", @company_name)
    build_attribute(data, "AssemblyProduct", @product_name)
    build_attribute(data, "AssemblyCopyright", @copyright)
    build_attribute(data, "AssemblyTrademark", @trademark)
    build_attribute(data, "ComVisible", @com_visible)
    build_attribute(data, "Guid", @com_guid)
    build_attribute(data, "AssemblyVersion", @version)
    build_attribute(data, "AssemblyFileVersion", @file_version)
    build_attribute(data, "AssemblyInformationalVersion", @informational_version)    
    
    data << ""
    
    unless @custom_attributes.empty?
      build_custom_attributes(data)
      data << ""
    end

    build_custom_data(data)

    data.concat(build_footer)

    chomp(data)
  end

  def build_attribute(data, attr_name, attr_data, allow_empty_args = false)
    return if (!allow_empty_args and attr_data.nil?)
    
    attr_value = @lang_engine.build_attribute(attr_name, attr_data)
    attr_re = @lang_engine.build_attribute_re(attr_name)
    
    @logger.debug "Building AssemblyInfo attribute: #{attr_value}"
    
    result = nil
    data.each do |line|
      break if result
      result = line.sub!(attr_re, attr_value) if line
    end
    
    data << attr_value if result.nil?
  end
  
  def build_custom_data(data)
    @custom_data.each do |cdata| 
      data << cdata unless data.include? cdata
    end
  end
  
  def build_using_statements(data)
    @namespaces.map do |ns| 
      @lang_engine.build_using_statement(ns) unless data.index { |line| line.match(ns) }
    end
  end

  def build_custom_attributes(data)
    @custom_attributes.each do |key, value|
      build_attribute(data, key, value, true)
    end
  end

  def chomp(ary)
    non_empty_rindex = ary.rindex {|line| !line.empty? } || 0
    ary.slice(0..non_empty_rindex)
  end

  def build_header
    @lang_engine.respond_to?(:before) ? [@lang_engine.before()] : []
  end

  def build_footer
    @lang_engine.respond_to?(:after) ? [@lang_engine.after()] : []
  end

  def read_input(file)
    data = []
    File.open(file, "r") do |f|
      f.each_line do |line|
        data << line.strip
      end
    end

    data
  end

  def write_output(output)
    File.open(@output_file, "w") do |f|
      output.each do |line|
        f.puts line
      end
    end
  end
end
