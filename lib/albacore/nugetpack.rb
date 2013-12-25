require "albacore/albacoretask"
require "albacore/config/nugetpackconfig"
require "albacore/support/supportlinux"

class NuGetPack
  TaskName = :nugetpack

  include Albacore::Task
  include Albacore::RunCommand
  include Configuration::NuGetPack
  include SupportsLinuxEnvironment
  
  attr_reader   :symbols
  
  attr_accessor :nuspec,
                :output,
                :base_folder

  attr_hash     :properties

  def initialize()
    super()
    update_attributes(nugetpack.to_hash)
    @command = "nuget"
  end

  def execute  
    unless @nuspec
      fail_with_message("nugetpack requires #nuspec" )
      return
    end
    
    result = run_command("nugetpack", build_parameters)
    fail_with_message("NuGet Pack failed, see the build log for more details.") unless result
  end

  def symbols
    @symbols = true
  end
  
  def build_parameters
    p = []
    p << "pack"
    p << "-Symbols" if @symbols
    p << "\"#{@nuspec}\""
    p << "-BasePath \"#{@base_folder}\"" if @base_folder
    p << "-OutputDirectory \"#{@output}\"" if @output
    p << "-Properties #{@properties.map { |k, v| "#{k}=\"#{v}\"" }.join(";")}" if @properties
    p
  end
end
