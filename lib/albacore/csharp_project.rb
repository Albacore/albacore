require_relative 'project'
module Albacore
  class CsharpProject < Project
    def initialize(project_path)
      super(project_path)
      sanity_checks
    end


    private
    def sanity_checks
      super
      warn { "project '#{@proj_filename}' is not a csharp project." } unless (File.extname(@proj_filename) =='.csproj')
    end
  end
end