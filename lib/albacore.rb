require 'albacore/version'
require 'albacore/albacore_module'
require 'albacore/rake_overrides'
require 'albacore/dsl'
require 'albacore/fsharp_project'
require 'albacore/csharp_project'
require 'albacore/vb_project'


module Albacore
  def self.create_project(project)
    path=Pathname.new(project)
    case path.extname
      when ".fsproj"
        FsharpProject.new(path)
      when ".csproj"
        CsharpProject.new(path)
      when ".vbproj"
        VbProject.new(path)
    end
  end
end
