require_relative 'project'
module Albacore
  class CsharpProject < Project
    def initialize(project_path)
      super(project_path)
      sanity_checks
    end

# Get AssemblyInfo path
# @return string or nil if path not found
#     def assembly_info_path
#       result=@proj_xml_node.css("Compile[Include*='AssemblyInfo.cs']").first.attributes["Include"].value
#       if result.nil?
#         @proj_path_base
#       else
#         File.expand_path(result[:Include])
#       end
#     end
    private
    def sanity_checks
      super
      warn { "project '#{@proj_filename}' is not a csharp project." } unless (File.extname(@proj_filename) =='.csproj')
    end
  end
end