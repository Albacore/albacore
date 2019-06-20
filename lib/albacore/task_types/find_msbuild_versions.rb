require 'rake'
require 'albacore/logging'
require 'json'

module Albacore
  extend Logging

  def self.find_msbuild_versions
    return nil unless ::Rake::Win32.windows?
    require 'win32/registry'
    retval = Hash.new

    # Older MSBuild versions
    begin
      Win32::Registry::HKEY_LOCAL_MACHINE.open('SOFTWARE\Microsoft\MSBuild\ToolsVersions') do |toolsVersion|
        toolsVersion.each_key do |key|
          begin
            versionKey = toolsVersion.open(key)
            version = key.to_i
            msb = File.join(versionKey['MSBuildToolsPath'],'msbuild.exe')
            retval[version] = msb
          rescue
            error "failed to open #{key}"
          end
        end
      end
    rescue
      error "failed to open HKLM\\SOFTWARE\\Microsoft\\MSBuild\\ToolsVersions"
    end

    # MSBuild bundled with Visual Studio 2017 and up
    instances_dir = File.join(ENV['ProgramData'].gsub('\\', '/'), 'Microsoft', 'VisualStudio', 'Packages', '_Instances')

    if Dir.exists?(instances_dir)
      Dir[File.join(instances_dir, "*")].each do |instance_dir|
        state_file = File.join(instance_dir, "state.json")

        if File.exists?(state_file)
          state = JSON.parse(File.read(state_file))

          installation_path = state["installationPath"]
          packages = state["selectedPackages"]
          next if installation_path.nil? || packages.nil?

          msbuild_component = packages.find { |package| package["id"] == "Microsoft.Component.MSBuild" }
          next if msbuild_component.nil?

          msbuild_version = msbuild_component["version"]
          next if msbuild_version.nil?

          msbuild_major_version = Integer(msbuild_version.partition('.').first) rescue nil
          next if msbuild_major_version.nil?

          installation_path_native = installation_path.gsub('\\', '/')

          msbuild_current_folder = File.join(installation_path_native, "MSBuild", "Current")
          msbuild_15_folder = File.join(installation_path_native, "MSBuild", "15.0")

          msbuild_folder = nil
          msbuild_folder = (msbuild_current_folder if Dir.exist?(msbuild_current_folder)) ||
                           (msbuild_15_folder if Dir.exist?(msbuild_15_folder))

          if !msbuild_folder.nil? && Dir.exists?(msbuild_folder)
            retval[msbuild_major_version] = File.join(msbuild_folder, "Bin", "MSBuild.exe")
          end
        end
      end
    end
    
    return retval
  end
end
