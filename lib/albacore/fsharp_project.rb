require_relative 'project'
module Albacore
  class FsharpProject < Project
    def initialize(project_path)
      super(project_path)
      sanity_checks
    end
    def assembly_info
      File.join properties_path,'AssemblyInfo.fs'
    end
    private
    def sanity_checks
      super
       warn { "project '#{@proj_filename}' is not an fsharp project." } unless (File.extname(@proj_filename) =='.fsproj')
    end
  end
end