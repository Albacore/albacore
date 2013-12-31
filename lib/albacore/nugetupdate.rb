require "albacore/albacoretask"
require "albacore/config/nugetupdateconfig"

class NuGetUpdate
  TaskName = :nugetupdate

  include Albacore::Task
  include Albacore::RunCommand
  include Configuration::NuGetUpdate
  
  attr_reader   :safe
  
  attr_accessor :input_file,
                :repository_path
  
  attr_array    :source,
                :id

  def initialize()
    @command = "nuget"
    
    super()
    update_attributes(nugetupdate.to_hash)
  end

  def execute
    unless @input_file
      fail_with_message("nugetupdate requires #input_file")
      return
    end
    
    result = run_command("nugetupdate", build_parameters)
    fail_with_message("NuGet Update failed, see the build log for more details.") unless result
  end
  
  def build_parameters
    p = []
    p << "update"
    p << "\"#{@input_file}\""
    p << "-Source \"#{@source.join(";")}\"" if @source
    p << "-Id \"#{@id.join(";")}\"" if @id
    p << "-RepositoryPath #{@repository_path}" if @repository_path
    p << "-Safe" if @safe
    p
  end
  
  def safe
    @safe = true
  end
end