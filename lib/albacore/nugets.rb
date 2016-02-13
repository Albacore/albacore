module Albacore
  module Nugets
    def self.find_nuget_gem_exe
      spec = Gem::Specification.find_by_name("nuget")
      File.join(spec.gem_dir, "bin", "nuget.exe")
    end
  end
end