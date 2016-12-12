require_relative 'project'
module Albacore
  class FsharpProject < Project
    def initialize(project_path)
      super(project_path)
      sanity_checks
    end

    def default_assembly_version
      begin
        info= File.read(assembly_info_path)
        v   = info.each_line
                  .select { |l| !(l.start_with?('//')||l.start_with?('(*')) && l.include?('AssemblyVersion(') }.first
        reg = /"(.*?)"/
        reg.match(v).captures.first
      rescue
        '1.0.0.0'
      end

    end

    private
    def sanity_checks
      super
       warn { "project '#{@proj_filename}' is not an fsharp project." } unless (File.extname(@proj_filename) =='.fsproj')
    end
  end
end